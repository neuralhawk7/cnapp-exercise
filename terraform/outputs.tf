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
  value       = data.aws_subnet.public_existing.id
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = data.aws_internet_gateway.existing.id
}
