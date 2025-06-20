resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets
  tags = { Name = "${var.project_name}-rds-subnet-group" }
}
resource "aws_db_instance" "main" {
  identifier           = "${var.project_name}-main-db"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = var.rds_instance_class
  allocated_storage    = var.rds_allocated_storage
  storage_type         = "gp3"
  db_name              = var.rds_db_name
  username             = var.rds_username
  password             = var.rds_password
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  multi_az               = true
  publicly_accessible    = false
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.project_name}-final-snapshot"
  backup_retention_period = 7
  tags = { Name = "${var.project_name}-main-db", Project = var.project_name }
}
resource "aws_db_instance" "replica" {
  count                = 1
  identifier           = "${var.project_name}-replica-${count.index}"
  replicate_source_db  = aws_db_instance.main.id
  instance_class       = var.rds_instance_class
  publicly_accessible  = false
  skip_final_snapshot  = true
  tags = { Name = "${var.project_name}-replica-db", Project = var.project_name }
}
