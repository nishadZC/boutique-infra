module "vpc" {
  source = "./modules/vpc"

  vpc_name     = "${var.vpc_name}-${var.environment}"
  cidr_block   = var.vpc_cidr
  subnet_cidrs = [for s in var.subnets : s.cidr_block]
  availability_zones = [for s in var.subnets : s.availability_zone]
  cluster_name     = "${var.cluster_name}-${var.environment}"
}


module "eks" {
  source = "./modules/eks"

  cluster_name     = "${var.cluster_name}-${var.environment}"
  node_group_name  = "${var.node_group_name}-${var.environment}"

  instance_types = var.instance_types
  min_size       = var.min_size
  desired_size   = var.desired_size
  max_size       = var.max_size

  subnet_ids = module.vpc.subnet_ids
  depends_on = [module.vpc]
}

module "ecr" {
  source = "./modules/ecr"
  repositories = var.repositories
}



module "argocd" {
  source = "./modules/argocd"
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
  depends_on = [module.eks, helm_release.aws_load_balancer_controller]
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${module.eks.cluster_name}-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.oidc_issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

data "http" "aws_load_balancer_controller_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name_prefix = "AWSLoadBalancerController-"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.aws_load_balancer_controller_iam_policy.response_body
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "helm_release" "aws_load_balancer_controller" {
  provider   = helm.eks
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.1"

  create_namespace = false

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "region"
    value = var.region
  }

  depends_on = [aws_iam_role_policy_attachment.aws_load_balancer_controller, module.eks]
}

data "aws_caller_identity" "current" {}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.1"
  
  description             = "KMS key for boutique"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  aliases                 = ["alias/boutique-${var.environment}"]
}


module "rds" {
  source  = "cloudposse/rds-cluster/aws"
  version = "1.7.0"

  name                 = "boutique-rds-${var.environment}"
  engine               = "aurora-postgresql"
  engine_mode          = "provisioned"
  cluster_family       = "aurora-postgresql14"
  cluster_size         = 1
  cluster_type         = "regional"
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
