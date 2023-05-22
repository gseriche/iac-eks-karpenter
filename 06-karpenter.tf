resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = false

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/karpenter-controller-${local.cluster_name}"
  }

  set {
    name  = "clusterName"
    value = local.cluster_name
  }

  set {
    name  = "clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "replicas"
    value = 1
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = "KarpenterNodeInstanceProfile-${local.cluster_name}"
  }

  depends_on = [module.eks]
}

resource "time_sleep" "wait_before_karpenter" {
  triggers = {
    karpenter_name = helm_release.karpenter.name
    manifest       = helm_release.karpenter.manifest
  }
  create_duration = "90s"
}

resource "kubectl_manifest" "karpenter-provisioner" {
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: default
  spec:
    requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: [${join(",", var.capacity_type)}]
      - key: node.kubernetes.io/instance-type
        operator: In
        values: [${join(",", var.allowed_instance_types)}]

    limits:
      resources:
        cpu: ${var.max_cpus_allowed}

    ttlSecondsAfterEmpty: 30
    ttlSecondsUntilExpired: ${var.instance_time_to_live}

    provider:
      subnetSelector:
        karpenter.sh/discovery: ${local.cluster_name}
      securityGroupSelector:
        karpenter.sh/discovery/${local.cluster_name}: ${local.cluster_name}
      tags:
        karpenter.sh/discovery/${local.cluster_name}: ${local.cluster_name}
        created-by: ${time_sleep.wait_before_karpenter.triggers["karpenter_name"]}
  YAML

  depends_on = [
    time_sleep.wait_before_karpenter
  ]
}

resource "kubectl_manifest" "aws-console-read-access" {
  yaml_body = <<-YAML
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRole
  metadata:
    name: eks-console-dashboard-full-access-clusterrole
  rules:
  - apiGroups:
    - ""
    resources:
    - nodes
    - namespaces
    - pods
    - configmaps
    - endpoints
    - events
    - limitranges
    - persistentvolumeclaims
    - podtemplates
    - replicationcontrollers
    - resourcequotas
    - secrets
    - serviceaccounts
    - services
    verbs:
    - get
    - list
  - apiGroups:
    - apps
    resources:
    - deployments
    - daemonsets
    - statefulsets
    - replicasets
    verbs:
    - get
    - list
  - apiGroups:
    - batch
    resources:
    - jobs
    - cronjobs
    verbs:
    - get
    - list
  - apiGroups:
    - coordination.k8s.io
    resources:
    - leases
    verbs:
    - get
    - list
  - apiGroups:
    - discovery.k8s.io
    resources:
    - endpointslices
    verbs:
    - get
    - list
  - apiGroups:
    - events.k8s.io
    resources:
    - events
    verbs:
    - get
    - list
  - apiGroups:
    - extensions
    resources:
    - daemonsets
    - deployments
    - ingresses
    - networkpolicies
    - replicasets
    verbs:
    - get
    - list
  - apiGroups:
    - networking.k8s.io
    resources:
    - ingresses
    - networkpolicies
    verbs:
    - get
    - list
  - apiGroups:
    - policy
    resources:
    - poddisruptionbudgets
    verbs:
    - get
    - list
  - apiGroups:
    - rbac.authorization.k8s.io
    resources:
    - rolebindings
    - roles
    verbs:
    - get
    - list
  - apiGroups:
    - storage.k8s.io
    resources:
    - csistoragecapacities
    verbs:
    - get
    - list
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: eks-console-dashboard-full-access-binding
  subjects:
  - kind: Group
    name: eks-console-dashboard-full-access-group
    apiGroup: rbac.authorization.k8s.io
  roleRef:
    kind: ClusterRole
    name: eks-console-dashboard-full-access-clusterrole
    apiGroup: rbac.authorization.k8s.io
  YAML
}
