# [K3D](https://k3d.io/) (K3s in Docker)

install specific release

```shell
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=v5.6.3 bash
```

install latest release

```shell
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

install kubectl if it is not already installed on the machine

```shell
{
wget -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl
}
```

execute the script that will run K3s clusters locally with an image registry `localhost:5000`

```bash
curl -s https://raw.githubusercontent.com/phosae/kube-setup/master/k3d/k3d-up.sh | bash
```

verify the cluster by Pod creation

```shell
{
REG_PORT=${REG_PORT:-5000}
docker tag nginx:latest localhost:$REG_PORT/mynginx:v0.1
docker push localhost:$REG_PORT/mynginx:v0.1
kubectl run mynginx --image localhost:$REG_PORT/mynginx:v0.1
}
```

teardown the cluster

```
{
CLUSTER_NAME=${CLUSTER_NAME:-k3d}
k3d cluster delete $CLUSTER_NAME
}
```