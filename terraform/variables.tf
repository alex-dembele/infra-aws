variable "aws_region" {
  description = "La région AWS pour déployer l'infrastructure."
  type        = string
  default     = "eu-west-3"
}
variable "project_name" {
  description = "Nom du projet, utilisé pour nommer les ressources."
  type        = string
  default     = "my-prod-app"
}
variable "vpc_cidr" {
  description = "Le bloc CIDR pour le VPC."
  type        = string
  default     = "10.0.0.0/16"
}
variable "rds_instance_class" {
  description = "Classe d'instance pour RDS."
  type        = string
  default     = "db.t4g.medium"
}
variable "rds_allocated_storage" {
  description = "Stockage alloué pour RDS en GB."
  type        = number
  default     = 20
}
variable "rds_db_name" {
  description = "Nom de la base de données."
  type        = string
  default     = "mydatabase"
}
variable "rds_username" {
  description = "Nom d'utilisateur pour la base de données."
  type        = string
  sensitive   = true
}
variable "rds_password" {
  description = "Mot de passe pour la base de données."
  type        = string
  sensitive   = true
}
variable "bastion_instance_type" {
  description = "Type d'instance pour le bastion."
  type        = string
  default     = "t3.micro"
}
variable "bastion_ssh_key_name" {
  description = "Nom de la paire de clés EC2 pour se connecter au bastion."
  type        = string
  default     = "votre-cle-ssh" # REMPLACER par le nom de votre clé dans AWS
}
variable "my_ip" {
  description = "Votre adresse IP pour autoriser la connexion SSH au bastion."
  type        = string
  default     = "0.0.0.0/0" # REMPLACER par votre IP (ex: "88.112.55.120/32") pour la sécurité
}
variable "domain_name" {
  description = "Le nom de domaine principal géré dans Route 53."
  type        = string
  default     = "votre-domaine.com" # REMPLACER
}
