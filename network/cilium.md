# [cilium](https://docs.cilium.io)

## intall cilium cli

```bash
{
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin

rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
}
```

## add cilium as chain plugin

```bash
{
CNI_CONF=$(cat /etc/cni/net.d/10-calico.conflist  | jq '.plugins[.plugins | length] |=.+ {"type": "cilium-cni"} | .name="generic-veth"')

cat << EOF | kubectl apply  -o yaml -v 9 -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cilium-chain-configuration
  namespace: kube-system
data:
  cni-config: '$CNI_CONF'
EOF

helm repo add cilium https://helm.cilium.io/

helm install cilium cilium/cilium --version 1.14.0 \
  --namespace=kube-system \
  --set cni.chainingMode=generic-veth \
  --set cni.customConf=true \
  --set cni.configMap=cilium-chain-configuration \
  --set routingMode=native \
  --set enableIPv4Masquerade=false \
  --set enableIdentityMark=false
}
```

verify status and connectivity

```bash
{
cilium status --wait
cilium connectivity test
}
```

## todo cilium as main CNI