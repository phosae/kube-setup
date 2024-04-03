#!/bin/bash
set -o errexit

IMAGE=${IMAGE:-rancher/k3s:v1.29.3-k3s1}
REG_NAME=${REG_NAME:-local-registry}
REG_PORT=${REG_PORT:-5000}
CLUSTER_NAME=${CLUSTER_NAME:-k3d}

# create registry container unless it already exists
if ! k3d registry list | grep -q "${REG_NAME}"; then
  k3d registry create "${REG_NAME}" --port "${REG_PORT}"
fi

# create a cluster with the local registry enabled
cat << EOT | k3d cluster create --registry-use k3d-${REG_NAME} --config -
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
EOT

cat <<EOT | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REG_PORT}"
    help: "https://k3d.io/usage/guides/registries/#using-a-local-registry"
EOT