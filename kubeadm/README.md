<!--ts-->
- [Creating a cluster with kubeadm](#creating-a-cluster-with-kubeadm)
  - [install kubeadm/kubelet/kubectl on all nodes](#install-kubeadmkubeletkubectl-on-all-nodes)
    - [install binary with curl](#install-binary-with-curl)
    - [install using native package management](#install-using-native-package-management)
  - [setup Container Runtime on all nodes](#setup-container-runtime-on-all-nodes)
    - [\[prerequisites\] Forwarding IPv4 and letting iptables see bridged traffic](#prerequisites-forwarding-ipv4-and-letting-iptables-see-bridged-traffic)
    - [containerd and runc (or crun/youki, etc)](#containerd-and-runc-or-crunyouki-etc)
    - [\[experimental\] replace runc with youki](#experimental-replace-runc-with-youki)
    - [bootstrap containerd](#bootstrap-containerd)
  - [bootstrap/init control plane](#bootstrapinit-control-plane)
  - [bootstrap/join all worker nodes](#bootstrapjoin-all-worker-nodes)
  - [result](#result)
  - [teardown](#teardown)
<!--te-->

# Creating a cluster with kubeadm

Things really help
- tmux `set synchronize-panes on`
- `rsync -a ~/clash-for-linux user@host:/root/`

## install kubeadm/kubelet/kubectl on all nodes

### install binary with curl

```bash
for kubebin in kubelet kubeadm kubectl; do
    curl -LO "https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/$kubebin"
    chmod +x $kubebin
    mv $kubebin /usr/local/bin/$kubebin
done
```

In China you can use [DaoCloud's public-binary-files-mirror](https://github.com/DaoCloud/public-binary-files-mirror)

```bash
for kubebin in kubelet kubeadm kubectl; do
    curl -LO "https://files.m.daocloud.io/dl.k8s.io/release/v1.28.4/bin/linux/amd64/$kubebin"
    chmod +x $kubebin
    mv $kubebin /usr/local/bin/$kubebin
done
```

### install using native package management

```bash
{
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
}
```

In China you can use [Kubernetes mirror on Aliyun](https://developer.aliyun.com/mirror/kubernetes/)

```bash
{
apt-get update && apt-get install -y apt-transport-https ca-certificates curl
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet=1.28.2-00 kubeadm=1.28.2-00 kubectl=1.28.2-00
}
```

## setup Container Runtime on all nodes

### [prerequisites] Forwarding IPv4 and letting iptables see bridged traffic

The following steps apply common settings for Kubernetes nodes on Linux. 
These steps are usually needed by [Network Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/).

```bash
{
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
}
```

Verify that the br_netfilter, overlay modules are loaded,
the `net.bridge.bridge-nf-call-iptables`, `net.bridge.bridge-nf-call-ip6tables`, and `net.ipv4.ip_forward` system variables are set to 1

```shell
{
lsmod | grep br_netfilter
lsmod | grep overlay

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
}
```

### containerd and runc (or crun/youki, etc)

install [containerd](https://github.com/containerd/containerd) from github release, or just `apt-get install containerd`

```bash
{
CONTAINERD_FILE="containerd-1.7.9-linux-amd64.tar.gz"
wget https://github.com/containerd/containerd/releases/download/v1.7.9/$CONTAINERD_FILE
tar Cxzvf /usr/local $CONTAINERD_FILE
mkdir -p /etc/containerd 
containerd config default > /etc/containerd/config.toml
rm $CONTAINERD_FILE
}
```

update the config `/etc/containerd/config.toml`

```toml
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.9"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

```bash
containerd config default | sed -r  's|registry.k8s.io/pause:(.*)"|registry.aliyuncs.com/google_containers/pause:\1"|' | sed -r 's|SystemdCgroup(.*)false$|SystemdCgroup\1true"|'  > /etc/containerd/config.toml
```

install [runc](https://github.com/opencontainers/runc) (`apt-get install containerd` install runc, too)

```bash
{
wget https://github.com/opencontainers/runc/releases/download/v1.1.10/runc.amd64
install -m 755 runc.amd64 /usr/local/bin/runc
rm runc.amd64
}
```

### [experimental] replace runc with [youki](https://github.com/containers/youki)

```bash
{
sudo apt-get install  -y  \
      pkg-config          \
      libsystemd-dev      \
      libdbus-glib-1-dev  \
      build-essential     \
      libelf-dev          \
      libseccomp-dev      \
      libclang-dev        \
      libssl-dev

sudo rm -f /usr/bin/runc /usr/local/bin/runc /usr/sbin/runc
wget https://github.com/containers/youki/releases/download/v0.3.0/youki_0_3_0_linux.tar.gz
tar -zxvf youki_0_3_0_linux.tar.gz youki_0_3_0_linux/youki-0.3.0/youki
sudo chmod 755 youki_0_3_0_linux/youki-0.3.0/youki
mv youki_0_3_0_linux/youki-0.3.0/youki /usr/local/bin/runc
rm -rf youki_0_3_0_linux.tar.gz youki_0_3_0_linux
}
```

### bootstrap containerd

```bash
{
cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload && systemctl enable containerd && systemctl start containerd
}
```

## bootstrap/init control plane

```bash
{
cat <<EOF | tee kubeadm-config.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v1.27.4
imageRepository: registry.aliyuncs.com/google_containers
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
  podSubnet: 172.20.0.0/16
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF

kubeadm init --config kubeadm-config.yaml

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint node --all node-role.kubernetes.io/control-plane:NoSchedule-
}
```

To use Cilium’s [kubeproxy-free functionality](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/), you can init cluster with the option `skip-phases=addon/kube-proxy`

```
kubeadm init --config kubeadm-config.yaml --skip-phases=addon/kube-proxy 
```

make some shorthand alias for `kubectl`

```bash
{
cat <<EOF >> ~/.bashrc
source <(kubectl completion bash)
alias k='kubectl'
complete -o default -F __start_kubectl k
alias ks='kubectl -n kube-system'
complete -o default -F __start_kubectl ks
EOF
source ~/.bashrc
}
```

## bootstrap/join all worker nodes

```bash
kubeadm join <master>:6443 --token <token> \
        --discovery-token-ca-cert-hash <hash>
```

regenerate join command

```bash
kubeadm token create --print-join-command
```

## result

After running the `kubeadm init` and `kubeadm join` processes, the cluster looks like this

```
root@master:~# kubectl get nodes
NAME              STATUS     ROLES           AGE   VERSION
master   NotReady   control-plane   28s   v1.28.4
worker   NotReady   <none>          7s    v1.28.4
root@master:~# kubectl get po -A
NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
kube-system   coredns-7bdc4cb885-g4wp2                  0/1     Pending   0          19s
kube-system   coredns-7bdc4cb885-gqlkj                  0/1     Pending   0          19s
kube-system   etcd-master                               1/1     Running   3          34s
kube-system   kube-apiserver-master                     1/1     Running   3          34s
kube-system   kube-controller-manager-master            1/1     Running   0          34s
kube-system   kube-proxy-4jqks                          1/1     Running   0          13s
kube-system   kube-proxy-4mfrg                          1/1     Running   0          19s
kube-system   kube-scheduler-master                     1/1     Running   3          33s
```

The Nodes and CoreDNS Pods are not ready because the [Network Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) are not installed.

You can refer to the [network section](../network/) and choose a Network Plugin to install. 

Once you have chosen and installed a Network Plugin, it will configure the pod networking and make the Nodes and Pods ready.

## teardown

```bash
kubeadm reset
```

The reset process does not clean CNI configuration. To do so, you must remove `/etc/cni/net.d`

```shell
rm /etc/cni/net.d/*
```