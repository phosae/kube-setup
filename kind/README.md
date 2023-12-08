# [KinD](https://kind.sigs.k8s.io/) (Kubernetes in Docker)

[KinD](https://kind.sigs.k8s.io/) Installation

```bash
GOBIN=/usr/local/bin/ go install sigs.k8s.io/kind@v0.20.0
```

Install kubectl if it is not already installed on the machine

```shell
{
wget -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.28.4/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kubectl
}
```

execute the script that run K8s clusters locally with an image registry `localhost:5000`,
and make master nodes schedulable

```bash
{
curl -s https://raw.githubusercontent.com/phosae/kube-setup/master/kind/kind-up.sh | bash
kubectl taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/control-plane:NoSchedule-
}
```