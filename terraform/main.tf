# Configuration du provider AWS
provider "aws" {
  region = var.aws_region
}
# Configuration du backend S3
# terraform {
#   backend "s3" {
#     bucket         = "votre-nom-de-bucket-tfstate-unique"
#     key            = "global/eks/terraform.tfstate"
#     region         = "eu-west-3" 
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
