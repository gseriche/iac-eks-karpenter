

resource "aws_eip" "nat" {
  count = 3
  vpc   = true

  tags = {
    "Name" = "EIP for NAT Gateway"
  }
}

module "vpc" {
  #checkov:skip=CKV_AWS_130: "Ensure VPC subnets do not assign public IP by default"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  #checkov:skip=CKV2_AWS_12: "Ensure the default security group of every VPC restricts all traffic"

  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "lero-devops-vpc"
  cidr = local.vpc_cidr
  azs  = local.azs

  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true
  reuse_nat_ips        = true
  external_nat_ip_ids  = aws_eip.nat.*.id

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "owned",
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.cluster_name
  }
}
