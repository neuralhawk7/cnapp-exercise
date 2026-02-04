
############################
# Create VPC (via module)
############################
module "vpc" {
  source  = "./modules/vpc"
  name    = var.name
  cidr_block = var.vpc_cidr
  public_subnets = var.public_subnet_cidrs
  azs = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
}

data "aws_availability_zones" "available" {}

############################
# EKS cluster (terraform-aws-modules/eks)
############################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # Managed node groups intentionally left out for now; add node groups as needed
}

############################
# Debian 10 (Buster) AMI
############################
data "aws_ami" "debian10" {
  most_recent = true
  owners      = ["136693071363"] # Debian on AWS

  filter {
    name   = "name"
    values = ["debian-10-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################
# Security Group:
# - SSH public
# - Mongo restricted to VPC CIDR (K8s network only)
############################
resource "aws_security_group" "mongo_vm" {
  name        = "${var.name}-mongo-vm-sg"
  description = "Public SSH; Mongo only from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from Internet (required by assignment)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  ingress {
    description = "MongoDB from VPC only (Kubernetes network)"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-mongo-vm-sg" }
}

############################
# Highly privileged instance profile (intentionally)
############################
resource "aws_iam_role" "mongo_vm_role" {
  name = "${var.name}-mongo-vm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.mongo_vm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "mongo_vm_profile" {
  name = "${var.name}-mongo-vm-profile"
  role = aws_iam_role.mongo_vm_role.name
}

############################
# S3 bucket for backups (public read + public listing)
############################
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "backups" {
  bucket        = "${var.name}-mongo-backups-${random_string.suffix.result}"
  force_destroy = true
}

# Disable block public access so public policy works
resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Public read (GetObject) + Public listing (ListBucket)
resource "aws_s3_bucket_policy" "public_read_and_list" {
  bucket = aws_s3_bucket.backups.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicListBucket",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:ListBucket"],
        Resource  = [aws_s3_bucket.backups.arn]
      },
      {
        Sid       = "PublicReadObjects",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = ["${aws_s3_bucket.backups.arn}/*"]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.backups]
}

############################
# EC2: Mongo VM
############################
resource "aws_instance" "mongo" {
  ami                         = data.aws_ami.debian10.id
  instance_type               = var.instance_type
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [aws_security_group.mongo_vm.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.mongo_vm_profile.name

  user_data = templatefile("${path.module}/mongo-vm/userdata.sh.tftpl", {
    mongo_admin_user = var.mongo_admin_user
    mongo_admin_pass = var.mongo_admin_pass
    backup_bucket    = aws_s3_bucket.backups.bucket
  })

  tags = { Name = "${var.name}-mongo-vm" }
}