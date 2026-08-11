module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.5.0"

  description             = "KMS key for boutique environment ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  aliases                 = ["alias/boutique-${var.environment}"]
}

module "rds" {
  source  = "cloudposse/rds-cluster/aws"
  version = "1.5.0"

  name                 = "boutique-db"
  environment          = var.environment
  engine               = "aurora-postgresql"
  cluster_family       = "aurora-postgresql14"
  cluster_size         = 1
  admin_user           = random_password.rds_admin_username.result
  admin_password       = random_password.rds_password.result
  db_name              = "boutique"
  db_port              = 5432
  vpc_id               = module.vpc.vpc_id
  security_groups      = [module.eks.cluster_security_group_id]
  subnets              = module.vpc.subnet_ids
  enable_http_endpoint = true
  kms_key_arn          = module.kms.key_arn
  storage_encrypted    = true

  scaling_configuration = [
    {
      auto_pause               = true
      max_capacity             = 16
      min_capacity             = 2
      seconds_until_auto_pause = 300
      timeout_action           = "ForceApplyCapacityChange"
    }
  ]
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
  value       = module.rds.endpoint
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
