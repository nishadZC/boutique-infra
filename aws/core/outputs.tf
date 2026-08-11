output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_urls" {
  value = module.ecr.repository_urls
}

output "kms_key_arn" {
  value = module.kms.key_arn
}


output "rds_cluster_endpoint" {
  value = module.rds.endpoint
}
