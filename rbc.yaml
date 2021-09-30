apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  namespace: aiops
  name: fabric8-rbac
subjects:
  - kind: ServiceAccount
    name: default
    namespace: aiops
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
  
