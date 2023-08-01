# K3d (Kubernetes in Docker)

run K8s clusters locally with an image registry `localhost:5000`

```shell
# the shell to immediately exit if any command encounters an execution error.
set -o errexit 

IMAGE=${IMAGE:rancher/k3s:v1.25.2-k3s1}

# create registry container unless it already exists
reg_name='k3d-registry'
reg_port='5000'
cluster_name='k3d'
if ! k3d registry list | grep -q "${reg_name}"; then
  k3d registry create "${reg_name}" --port "${reg_port}"
fi

# create a cluster with the local registry enabled in containerd
cat << EOF | k3d cluster create --config -
apiVersion: k3d.io/v1alpha4
kind: Simple
metadata:
  name: ${cluster_name}
servers: 1
agents: 2
image: $IMAGE
ports:
- port: 30000-30100:30000-30100
  nodeFilters:
  - server:*
options:
  k3s:
    extraArgs:
    - arg: --disable=traefik
      nodeFilters:
      - server:*
EOF

# connect the registry to the cluster network if not already connected
if ! k3d registry list | grep -q "${reg_name}"; then
  k3d registry create "${reg_name}" --port "${reg_port}"
  k3d registry connect "${cluster_name}" "${reg_name}"
fi

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://k3d.io/usage/guides/registries/#using-a-local-registry"
EOF

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: app
  name: app
spec:
  containers:
  - image: ${cluster_name}:${reg_port}/app:v1
    name: app
    ports:
    - containerPort: 80
EOF
```