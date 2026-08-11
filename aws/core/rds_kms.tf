module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.5.0"

  description             = "KMS key for boutique environment ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  aliases                 = ["alias/boutique-${var.environment}"]
}

resource "aws_db_subnet_group" "rds" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = module.vpc.database_subnets
}

resource "aws_db_instance" "rds" {
  identifier             = "boutique-db-${var.environment}"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  db_name                = "boutique"
  username               = random_password.rds_admin_username.result
  password               = random_password.rds_password.result
  parameter_group_name   = "default.postgres16"
  skip_final_snapshot    = true
  vpc_security_group_ids = [module.eks.cluster_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  port                   = 5432
  storage_encrypted      = true
  kms_key_id             = module.kms.key_arn

  tags = {
    Name = "${var.environment}-rds"
  }
}


resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#"
}

resource "random_password" "rds_admin_username" {
  length  = 7
  special = false
  numeric = false
}

resource "aws_ssm_parameter" "save_rds_db_name_to_ssm" {
  name        = "/${var.environment}/rds/db_name"
  description = "RDS DB name"
  type        = "SecureString"
  value       = "boutique"
}

resource "aws_ssm_parameter" "save_rds_endpoint_to_ssm" {
  name        = "/${var.environment}/rds/endpoint"
  description = "RDS endpoint"
  type        = "SecureString"
  value       = aws_db_instance.rds.endpoint
}

resource "aws_ssm_parameter" "save_rds_password_to_ssm" {
  name        = "/${var.environment}/rds/password"
  description = "RDS password"
  type        = "SecureString"
  value       = random_password.rds_password.result
}

resource "aws_ssm_parameter" "save_rds_admin_username_to_ssm" {
  name        = "/${var.environment}/rds/username"
  description = "RDS username"
  type        = "SecureString"
  value       = random_password.rds_admin_username.result
}
