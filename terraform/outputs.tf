output "eks_cluster_name" {
  description = "Nom du cluster EKS."
  value       = module.eks.cluster_name
}
output "eks_cluster_endpoint" {
  description = "Endpoint du cluster EKS."
  value       = module.eks.cluster_endpoint
}
output "karpenter_instance_profile_name" {
    description = "Nom du profil d'instance IAM pour les noeuds Karpenter."
    value       = module.eks.eks_managed_node_groups["core_services"].iam_instance_profile_name
}
output "rds_main_endpoint" {
  description = "Endpoint de l'instance RDS principale (pour l'écriture)."
  value       = aws_db_instance.main.address
  sensitive   = true
}
output "rds_replica_endpoint" {
  description = "Endpoint du replica RDS (pour la lecture)."
  value       = aws_db_instance.replica[0].address
  sensitive   = true
}
output "bastion_public_ip" {
  description = "IP publique du bastion host."
  value       = aws_instance.bastion.public_ip
}
output "configure_kubectl" {
  description = "Commande pour configurer kubectl"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${var.project_name}"
}
output "aws_lbc_iam_role_arn" {
  description = "ARN du rôle IAM pour AWS Load Balancer Controller"
  value       = aws_iam_role.aws_lbc.arn
}
output "external_dns_iam_role_arn" {
  description = "ARN du rôle IAM pour ExternalDNS"
  value       = aws_iam_role.external_dns.arn
}
output "karpenter_iam_role_arn" {
  description = "ARN du rôle IAM pour le contrôleur Karpenter"
  value       = aws_iam_role.karpenter.arn
}
