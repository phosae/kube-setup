# [🐊 Gatekeeper](https://github.com/open-policy-agent/gatekeeper) - Policy Controller for Kubernetes

```bash
{
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm install gatekeeper/gatekeeper --version 3.12.0 --name-template=gatekeeper --namespace gatekeeper-system --create-namespace
}
```

uninstall

```bash
helm uninstall gatekeeper --namespace gatekeeper-system
```

<!--ts-->
   * [Trick calico’s CNI conf name from 10-calico.conflist to30-calico.conflist](#trick-calicos-cni-conf-name-from-10-calicoconflist-to30-calicoconflist)
   * [Swap Pod Image](#swap-pod-image)
<!--te-->

## Trick calico’s CNI conf name from 10-calico.conflist to30-calico.conflist

```yaml
apiVersion: mutations.gatekeeper.sh/v1
kind: Assign
metadata:
  name: trick-calico-conflist
spec:
  applyTo:
    - groups: [""]
      versions: ["v1"]
      kinds: ["Pod"]
  match: 
    scope: Namespaced
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces: ["calico-*", "tigera-operator"]
  location: "spec.initContainers[name:*].env[name:CNI_CONF_NAME].value"
  parameters:
    pathTests:
    - subPath: "spec.initContainers[name:*].env[name:CNI_CONF_NAME].value"
      condition: MustExist
    assign:
      value: 30-calico.conflist
```

## Swap Pod Image
simple alternative to [estahn/k8s-image-swapper](https://github.com/estahn/k8s-image-swapper)

```yaml
apiVersion: mutations.gatekeeper.sh/v1alpha1
kind: AssignImage
metadata:
  name: acorn
spec:
  applyTo:
  - groups: [""]
    versions: ["v1"]
    kinds: ["Pod"]
  match:
    scope: Namespaced
    namespaces: ["acorn*"]
    kinds:
    - apiGroups: [ "*" ]
      kinds: ["Pod"]
  location: "spec.containers[name:*].image"
  parameters:
    assignDomain: "docker.io"
    assignPath: "zengxu/acorn"
    assignTag: ":v0.7.1"
---
apiVersion: mutations.gatekeeper.sh/v1
kind: Assign
metadata:
  name: acron-env-image
spec:
  applyTo:
  - groups: [""]
    versions: ["v1"]
    kinds: ["Pod"]
  match:
    scope: Namespaced
    namespaces: ["acorn*"]
    kinds:
    - apiGroups: ["*"]
      kinds: ["Pod"]
  parameters:
    pathTests:
    - condition: MustExist
      subPath: spec.containers[name:*].env[name:ACORN_IMAGE].value
    assign:
      value: docker.io/zengxu/acorn:v0.7.1
```
