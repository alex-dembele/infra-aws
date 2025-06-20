module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.project_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Karpenter gérera les nœuds applicatifs. Ce groupe est pour les services core.
  eks_managed_node_groups = {
    core_services = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t4g.medium"]
    }
  }

  enable_irsa = true

  # Rôles IAM pour les addons créés via le module EKS
  cluster_addons = {
    kube-proxy = {}
    vpc-cni    = {}
    coredns    = {}
    ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
  }
  
  tags = { Project = var.project_name }
}

# Rôle IRSA pour EBS CSI Driver (nécessaire pour les volumes persistants)
module "ebs_csi_driver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.0"

  role_name_prefix      = "${var.project_name}-ebs-csi-driver"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# --- Rôles IAM pour les Addons ---

# Rôle pour ExternalDNS
resource "aws_iam_role" "external_dns" {
  name = "${var.project_name}-external-dns-role"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json
}
data "aws_iam_policy_document" "external_dns_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:external-dns:external-dns"]
    }
  }
}
resource "aws_iam_policy" "external_dns" {
  name        = "${var.project_name}-external-dns-policy"
  policy = data.aws_iam_policy_document.external_dns.json
}
data "aws_iam_policy_document" "external_dns" {
  statement {
    actions   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }
  statement {
    actions   = ["route53:ListHostedZones"]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "external_dns" {
  policy_arn = aws_iam_policy.external_dns.arn
  role       = aws_iam_role.external_dns.name
}


# Rôle pour AWS Load Balancer Controller
resource "aws_iam_role" "aws_lbc" {
  name = "${var.project_name}-aws-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc_assume.json
}
data "aws_iam_policy_document" "aws_lbc_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}
resource "aws_iam_policy" "aws_lbc" {
    name = "${var.project_name}-AWSLoadBalancerControllerIAMPolicy"
    policy = file("${path.module}/aws_lbc_policy.json") # On va créer ce fichier
}
resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
}


# Rôle pour Karpenter
resource "aws_iam_role" "karpenter" {
  name = "${var.project_name}-karpenter-controller-role"
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume.json
  tags = { "karpenter.sh/discovery" = var.project_name }
}
data "aws_iam_policy_document" "karpenter_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }
  }
}
resource "aws_iam_policy" "karpenter" {
  name   = "${var.project_name}-KarpenterControllerPolicy"
  policy = data.aws_iam_policy_document.karpenter.json
}
data "aws_iam_policy_document" "karpenter" {
  statement {
    sid       = "Karpenter"
    effect    = "Allow"
    actions   = [
        "ec2:CreateLaunchTemplate", "ec2:CreateFleet", "ec2:RunInstances", "ec2:CreateTags",
        "iam:PassRole", "ec2:TerminateInstances", "ec2:DescribeLaunchTemplates", 
        "ec2:DescribeInstances", "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets",
        "ec2:DescribeInstanceTypes", "ec2:DescribeInstanceTypeOfferings", "ec2:DescribeAvailabilityZones",
        "ssm:GetParameter"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_role_policy_attachment" "karpenter" {
  policy_arn = aws_iam_policy.karpenter.arn
  role       = aws_iam_role.karpenter.name
}
resource "aws_iam_instance_profile" "karpenter" {
  name = "${var.project_name}-karpenter-profile"
  role = module.eks.eks_managed_node_groups["core_services"].iam_role_name # Attache au rôle des noeuds EKS
}
