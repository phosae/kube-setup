# [K3D](https://k3d.io/) (K3s in Docker)

Install current latest release

```shell
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

Install specific release

```shell
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.5.1 bash
```

run K3s clusters locally with an image registry `localhost:5000`

```shell
# the shell to immediately exit if any command encounters an execution error.
set -o errexit 

IMAGE=${IMAGE:-rancher/k3s:v1.27.4-k3s1}
REG_NAME=${REG_NAME:-local-registry}
REG_PORT=${REG_PORT:-5000}
CLUSTER_NAME=${CLUSTER_NAME:-k3d}

# create registry container unless it already exists
if ! k3d registry list | grep -q "${REG_NAME}"; then
  k3d registry create "${REG_NAME}" --port "${REG_PORT}"
fi

# create a cluster with the local registry enabled
cat << EOF | k3d cluster create --registry-use k3d-${REG_NAME} --config -
apiVersion: k3d.io/v1alpha5
kind: Simple
metadata:
  name: ${CLUSTER_NAME}
servers: 1
agents: 2
image: $IMAGE
registries:
  use:
    - k3d-${REG_NAME}:${REG_PORT}
  config: |
    mirrors:
      "localhost:${REG_PORT}":
        endpoint:
          - http://k3d-${REG_NAME}:5000
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

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REG_PORT}"
    help: "https://k3d.io/usage/guides/registries/#using-a-local-registry"
EOF
```

Verify cluster by Pod creation

```shell
{
REG_PORT=${REG_PORT:-5000}
docker tag nginx:latest localhost:$REG_PORT/mynginx:v0.1
docker push localhost:$REG_PORT/mynginx:v0.1
kubectl run mynginx --image localhost:$REG_PORT/mynginx:v0.1
}
```

Teardown cluster

```
{
CLUSTER_NAME=${CLUSTER_NAME:-k3d}
k3d cluster delete $CLUSTER_NAME
}
```