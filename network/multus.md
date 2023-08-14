# multus-cni

```bash
{
wget https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/v4.0.2/deployments/multus-daemonset-thick.yml

# sucks: there's no cp binary in v4.0.2. version snapshot-thick does have.
# sed -i 's~ghcr.io/k8snetworkplumbingwg/multus-cni:snapshot-thick~ghcr.io/k8snetworkplumbingwg/multus-cni:v4.0.2~g' multus-daemonset-thick.yml

sed -i 's~ghcr.io/k8snetworkplumbingwg/multus-cni:snapshot-thick~zengxu/multus-cni:snapshot-thick~g' multus-daemonset-thick.yml

kubectl apply -f multus-daemonset-thick.yml
}
```
