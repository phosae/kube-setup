# k8s-setup

the hard way: [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)

the easy way: [Creating a cluster with kubeadm](./kubeadm/)

development and testing way (local clusters IN Docker):
- [KinD](./kind/README.md), run Kubernetes using Docker container "nodes"
- [K3D](./k3d/README.md), run [K3s](https://github.com/k3s-io/k3s/) in Docker

## helm cli

on debian/ubuntu

```bash
{
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
}
```

or with bash shell

```bash
{
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
}
```