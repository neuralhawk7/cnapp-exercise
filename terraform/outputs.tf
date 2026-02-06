output "region" {
  description = "AWS region"
  value       = var.region
}

output "mongo_instance_id" {
  description = "MongoDB EC2 instance ID"
  value       = aws_instance.mongo.id
}

output "mongo_public_ip" {
  description = "Public IP of MongoDB instance"
  value       = aws_instance.mongo.public_ip
}

output "mongo_private_ip" {
  description = "Private IP of MongoDB instance"
  value       = aws_instance.mongo.private_ip
}

output "mongo_security_group_id" {
  description = "MongoDB security group ID"
  value       = aws_security_group.mongo_vm.id
}

output "backup_bucket_name" {
  description = "S3 bucket name for MongoDB backups"
  value       = aws_s3_bucket.backups.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnets[0]
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.igw_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}
