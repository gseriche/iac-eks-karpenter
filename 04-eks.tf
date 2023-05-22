module "eks" {
  #checkov:skip=CKV_AWS_58: "Ensure EKS Cluster has Secrets Encryption Enabled" - Already done with cluster encryption config
  #checkov:skip=CKV_AWS_37: "Ensure Amazon EKS control plane logging enabled for all log types" - Already done with cluster_enabled_log_types
  #checkov:skip=CKV_AWS_79: "Ensure Instance Metadata Service Version 1 is not enabled" - Already done in metadata options
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  #checkov:skip=CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"

  source  = "terraform-aws-modules/eks/aws"
  version = "19.10.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.24"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  #checkov:skip=CKV_AWS_39: "Ensure Amazon EKS public endpoint disabled"
  #checkov:skip=CKV_AWS_38: "Ensure Amazon EKS public endpoint not accessible to 0.0.0.0/0"
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa = true

  kms_key_enable_default_policy = true
  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # node_security_group_additional_rules - extends node-to-node security group rules
  node_security_group_additional_rules = {

    karpenter_webhook = {
      description                   = "Cluster API to AWS LB Controller webhook"
      protocol                      = "all"
      from_port                     = 0
      to_port                       = 65000
      type                          = "ingress"
      source_cluster_security_group = true
    }

  }

  node_security_group_tags = {
    "karpenter.sh/discovery/${local.cluster_name}" = local.cluster_name
  }
  cluster_security_group_tags = {
    "karpenter.sh/discovery/${local.cluster_name}" = local.cluster_name
  }


  eks_managed_node_groups = {
    initial = {
      # instance_types        = ["m6i.large", "m6id.large", "m6a.large", "m6in.large"]
      instance_types        = ["t3.medium", "t3a.medium", "t3.large", "t3a.large"]
      capacity_type         = "SPOT"
      create_security_group = false

      ami_type = "BOTTLEROCKET_x86_64"

      min_size     = 2
      max_size     = 4
      desired_size = 2

      tags = {
        "karpenter.sh/discovery/${local.cluster_name}" = local.cluster_name
      }


      metadata_options = {
        "http_endpoint" : "enabled",
        "http_tokens" : "required"
      }
      iam_role_additional_policies = {
        # Required by Karpenter
        S3            = "arn:aws:iam::aws:policy/AmazonS3FullAccess",
        SSMCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        EKSManagement = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      }

    }


  }

  create_kms_key = true
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  aws_auth_roles = []

  aws_auth_users = []

}

data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
  role       = module.eks.cluster_iam_role_name
  policy_arn = data.aws_iam_policy.ssm_managed_instance.arn
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${module.eks.cluster_name}"
  role = module.eks.eks_managed_node_groups["initial"].iam_role_name
}



module "karpenter_irsa" {
  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.16.0"

  role_name                          = "karpenter-controller-${module.eks.cluster_name}"
  attach_karpenter_controller_policy = true
  attach_vpc_cni_policy              = true
  vpc_cni_enable_ipv4                = true

  karpenter_tag_key               = "karpenter.sh/discovery/${module.eks.cluster_name}"
  karpenter_controller_cluster_id = module.eks.cluster_name
  karpenter_controller_node_iam_role_arns = [
    module.eks.eks_managed_node_groups["initial"].iam_role_arn
  ]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}
