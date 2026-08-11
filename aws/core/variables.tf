variable "region" {
  description="The name of the region"
  type = string
}

variable "vpc_name" {
  description = "VPC name"
  type = string
}

variable "vpc_cidr" {
  description = "VPC CIDR Value"
  type = string
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "database_subnets" {
  description = "List of database subnet CIDRs"
  type        = list(string)
}


variable "cluster_name" {
  description = "The name of the Kubernetes Cluster"
  type = string
}

variable "node_group_name" {
  type        = string
  description = "EKS node group name"
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types for worker nodes (t3.medium, t3.large)"
}

variable "capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT"
}

variable "desired_size" {
  type        = number
  description = "Desired number of worker nodes"
}

variable "min_size" {
  type        = number
  description = "Minimum number of  worker nodes"
}

variable "max_size" {
  type        = number
  description = "Maximum number of worker nodes"
}

variable "disk_size" {
  type        = number
}

variable "repositories" {
  type = list(string)
}

variable "environment" {
  type        = string
  description = "The environment name (e.g. dev, prod)"
}

variable "base_domain" {
  type        = string
  description = "The base domain name for Route 53"
}

variable "id_rsa" {
  type        = string
  description = "Public SSH key for Bastion host"
}