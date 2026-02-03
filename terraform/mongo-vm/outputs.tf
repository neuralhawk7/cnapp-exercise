output "mongo_public_ip" {
  value = aws_instance.mongo.public_ip
}

output "mongo_private_ip" {
  value = aws_instance.mongo.private_ip
}

output "backup_bucket" {
  value = aws_s3_bucket.backups.bucket
}