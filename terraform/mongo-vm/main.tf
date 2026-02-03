terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.30"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region
}

# --- Inputs: reuse existing EKS VPC + subnets ---
data "aws_vpc" "target" {
  id = var.vpc_id
}
############################
# Internet Gateway + Public Subnet
############################
data "aws_internet_gateway" "existing" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.target.id]
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = data.aws_vpc.target.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_subnet_az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.target.id
  tags   = { Name = "${var.name}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.existing.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
# Pick an older Debian AMI (Debian 10 "buster")
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

resource "aws_security_group" "mongo_vm" {
  name        = "mongo-vm-sg"
  description = "SSH + MongoDB access"
  vpc_id      = data.aws_vpc.target.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # MongoDB reachable from within VPC (tighten later if desired)
  ingress {
    description = "MongoDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.target.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Highly-privileged instance profile (intentionally broad)
resource "aws_iam_role" "mongo_vm_role" {
  name = "mongo-vm-role"
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
  name = "mongo-vm-profile"
  role = aws_iam_role.mongo_vm_role.name
}

# S3 bucket for backups (globally-unique)
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "backups" {
  bucket        = "mongo-backups-${random_string.suffix.result}"
  force_destroy = true
}

# Intentionally allow public read for validation
resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.backups.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = ["s3:GetObject"],
      Resource  = ["${aws_s3_bucket.backups.arn}/*"]
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.backups]
}

resource "aws_instance" "mongo" {
  ami                         = data.aws_ami.debian10.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.mongo_vm.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.mongo_vm_profile.name
  user_data = templatefile("${path.module}/userdata.sh", {
    mongo_admin_user = var.mongo_admin_user
    mongo_admin_pass = var.mongo_admin_pass
    backup_bucket    = aws_s3_bucket.backups.bucket
  })

  tags = { Name = "mongo-vm" }
}