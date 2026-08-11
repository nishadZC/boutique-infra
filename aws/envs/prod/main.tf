module "core" {
  source = "../../core"

  environment = "prod"
  
  region = "us-east-1"
  vpc_name = "boutique-vpc"
  vpc_cidr = "10.1.0.0/16"

  subnets = [
    {
      name = "subnet-1"
      cidr_block = "10.1.1.0/24"
      availability_zone = "us-east-1a"
    },
    {
      name = "subnet-2"
      cidr_block = "10.1.2.0/24"
      availability_zone = "us-east-1b"
    },
    {
      name = "subnet-3"
      cidr_block = "10.1.3.0/24"
      availability_zone = "us-east-1c"
    }
  ]

  cluster_name = "boutique-eks"
  node_group_name = "eks-node-group"

  instance_types = ["m7i-flex.large"] # Larger instance for prod
  capacity_type  = "ON_DEMAND"        # On demand for reliability

  desired_size = 2
  min_size     = 2
  max_size     = 5

  disk_size = 50

  repositories = [
    "frontend",
    "gateway",
    "auth",
    "order-service",
    "orders",
    "product-service",
    "user-service"
  ]
}
