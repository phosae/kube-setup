# [kindnetd](https://github.com/kubernetes-sigs/kind/tree/main/images/kindnetd)

just copy/paste from [kind/pkg/build/nodeimage/const_cni.go](https://github.com/kubernetes-sigs/kind/blob/f6964c9799a5514e65416eba2e5f04ccc5ef2dfb/pkg/build/nodeimage/const_cni.go#L41), and make some edit as we like

```
cat << EOF | kubectl create -f -
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: kindnet
rules:
  - apiGroups:
    - policy
    resources:
    - podsecuritypolicies
    verbs:
    - use
    resourceNames:
    - kindnet
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - list
      - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: kindnet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kindnet
subjects:
- kind: ServiceAccount
  name: kindnet
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kindnet
  namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kindnet
  namespace: kube-system
  labels:
    tier: node
    app: kindnet
    k8s-app: kindnet
spec:
  selector:
    matchLabels:
      app: kindnet
  template:
    metadata:
      labels:
        tier: node
        app: kindnet
        k8s-app: kindnet
    spec:
      hostNetwork: true
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
      - operator: Exists
      serviceAccountName: kindnet
      containers:
      - name: kindnet-cni
        image: kindest/kindnetd:v20230511-dc714da8
        env:
        - name: HOST_IP
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: POD_SUBNET
          value: 172.30.0.0/16
        volumeMounts:
        - name: cni-cfg
          mountPath: /etc/cni/net.d
        - name: xtables-lock
          mountPath: /run/xtables.lock
          readOnly: false
        - name: lib-modules
          mountPath: /lib/modules
          readOnly: true
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: false
          capabilities:
            add: ["NET_RAW", "NET_ADMIN"]
      volumes:
      - name: cni-cfg
        hostPath:
          path: /etc/cni/net.d
      - name: xtables-lock
        hostPath:
          path: /run/xtables.lock
          type: FileOrCreate
      - name: lib-modules
        hostPath:
          path: /lib/modules
EOF
```