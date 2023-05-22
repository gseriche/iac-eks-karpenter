# iac-eks-karpenter

Fast repository with VPC, EKS, Karpenter

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 4.58.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.9.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.19.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.9.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.58.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.9.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.14.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.9.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 19.10.0 |
| <a name="module_karpenter_irsa"></a> [karpenter\_irsa](#module\_karpenter\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.16.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.19.0 |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.terraform-lock](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/resources/dynamodb_table) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/resources/eip) | resource |
| [aws_iam_instance_profile.karpenter](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role_policy_attachment.karpenter_ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_key.terraform_kms_key](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/resources/kms_key) | resource |
| [aws_s3_bucket.bucket_backend](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.bucket_backend](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.bucket_backend](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.bucket_backend](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/resources/s3_bucket_versioning) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/2.9.0/docs/resources/release) | resource |
| [helm_release.metrics_server](https://registry.terraform.io/providers/hashicorp/helm/2.9.0/docs/resources/release) | resource |
| [kubectl_manifest.aws-console-read-access](https://registry.terraform.io/providers/gavinbunney/kubectl/1.14.0/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter-provisioner](https://registry.terraform.io/providers/gavinbunney/kubectl/1.14.0/docs/resources/manifest) | resource |
| [time_sleep.wait_before_karpenter](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.ssm_managed_instance](https://registry.terraform.io/providers/hashicorp/aws/4.58.0/docs/data-sources/iam_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_instance_types"></a> [allowed\_instance\_types](#input\_allowed\_instance\_types) | Which instance types Karpenter is allowed to spin up | `list(any)` | <pre>[<br>  "t3.medium",<br>  "t3a.medium",<br>  "t3.large",<br>  "t3a.large",<br>  "t3.2xlarge",<br>  "t3a.2xlarge",<br>  "m5.large",<br>  "m5a.large",<br>  "m5.2xlarge",<br>  "m5a.2xlarge",<br>  "m5.4xlarge",<br>  "m5a.4xlarge",<br>  "m5.8xlarge",<br>  "m5a.8xlarge",<br>  "c5.large",<br>  "c5a.large",<br>  "c5.2xlarge",<br>  "c5a.2xlarge",<br>  "c5.4xlarge",<br>  "c5a.4xlarge",<br>  "c5.9xlarge",<br>  "c5a.9xlarge",<br>  "c5d.12xlarge",<br>  "c5d.18xlarge",<br>  "c5d.24xlarge",<br>  "c5a.24xlarge",<br>  "c5.24xlarge"<br>]</pre> | no |
| <a name="input_bucket_backend_name"></a> [bucket\_backend\_name](#input\_bucket\_backend\_name) | Name of the backend bucket to be created | `string` | n/a | yes |
| <a name="input_capacity_type"></a> [capacity\_type](#input\_capacity\_type) | What types of nodes to spawn. Can be spot/on-demand, or both | `list(any)` | <pre>[<br>  "spot",<br>  "on-demand"<br>]</pre> | no |
| <a name="input_instance_time_to_live"></a> [instance\_time\_to\_live](#input\_instance\_time\_to\_live) | How long an individual instance will live for until the node is tainted | `number` | `3600` | no |
| <a name="input_max_cpus_allowed"></a> [max\_cpus\_allowed](#input\_max\_cpus\_allowed) | How many CPU cores will be allowed in the cluster | `string` | `"1000"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
