region = "us-east-1"
vpc_name = "boutique-vpc"
vpc_cidr = "10.1.0.0/16"

private_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
public_subnets   = ["10.1.3.0/24", "10.1.4.0/24"]
database_subnets = ["10.1.5.0/24", "10.1.6.0/24"]

cluster_name = "boutique-eks"
node_group_name = "eks-node-group"

instance_types = ["c7i-flex.large"]
capacity_type  = "ON_DEMAND"

desired_size = 2
min_size     = 1
max_size     = 3

disk_size = 5

repositories = [
  "frontend",
  "gateway",
  "auth",
  "order-service",
  "orders",
  "product-service",
  "user-service"
]
