# [Calico](https://docs.tigera.io/calico)

```bash
{
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

cat << EOF |  kubectl create -f -
# This section includes base Calico installation configuration.
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    bgp: Enabled   # Enabled, Disabled
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      cidr: 172.20.0.0/16
      encapsulation: VXLAN # IPIP, VXLAN, IPIPCrossSubnet, VXLANCrossSubnet, None
      natOutgoing: Enabled
      nodeSelector: all()
---
# This section configures the Calico API server.
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF
}
```

Multiple calico networks are only supported in Calico Cloud and Calico Enterprise, the community version only supports [IPPools migration](https://docs.tigera.io/calico/latest/networking/ipam/migrate-pools).

```
cat << EOF | k apply -f -
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: default-ipv4-ippool
spec:
  cidr: 172.20.0.0/16
  ipipMode: Never
  natOutgoing: true
  disabled: false
  nodeSelector: all()
  vxlanMode: Always
---
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: direct
spec:
  cidr: 172.25.0.0/16
  ipipMode: Never
  vxlanMode: Never
  disabled: true
  natOutgoing: true
---
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: ipip
spec:
  cidr: 172.30.0.0/16
  ipipMode: Always
  vxlanMode: Never
  disabled: true
  natOutgoing: true
EOF
```

The network CIDR and cluster mode can be switched by setting the `spec.disabled` field of multiple IPPools.

For example, by disabling the IP pool `default-ipv4-ippool` and enabling another IP pool, the cluster network can switch between VXLAN mode, IPIP mode, and BGP mode.

This function also supports using any PodCIDR that differs from the cluster-cidr configured by kubeadm.
