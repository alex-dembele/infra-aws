module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"
  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = [for k, v in data.aws_availability_zones.available.names : cidrsubnet(var.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in data.aws_availability_zones.available.names : cidrsubnet(var.vpc_cidr, 8, k + 4)]
  enable_nat_gateway = true
  single_nat_gateway = true
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
    "karpenter.sh/discovery"                    = var.project_name
  }
  tags = { Project = var.project_name }
}
