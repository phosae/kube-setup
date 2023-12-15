#!/bin/bash
set -o errexit

IMAGE=${IMAGE:-kindest/node:v1.29.0}

# create registry container unless it already exists
reg_name='kind-registry'
reg_port='5000'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# create a cluster with the local registry enabled in containerd
cat << EOT | kind create cluster --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kind
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:5000"]
featureGates:
  "ValidatingAdmissionPolicy": true          # alpha 1.26, 1.27, beta 1.28
  "UserNamespacesSupport": true # alpha 1.25, named UserNamespacesStatelessPodsSupport before 1.28
  "NFTablesProxyMode": true # alpha 1.29
runtimeConfig:
  "api/all": true # enable all built-in APIs
nodes:
  - role: control-plane
    image: $IMAGE
  - role: worker
    image: $IMAGE
  - role: worker
    image: $IMAGE
networking:
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/12"
  disableDefaultCNI: false # the default CNI will not be installed if it is configured to true
EOT

# connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

cat <<EOT | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOT