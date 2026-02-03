
############################
data "aws_vpc" "target" {
  id = var.vpc_id
}

############################
# Internet Gateway + Public Subnet
############################
resource "aws_internet_gateway" "igw" {
  vpc_id = data.aws_vpc.target.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = data.aws_vpc.target.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_subnet_az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet"
    # Not required for EC2, but harmless; helps if you ever use it for ELB
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.target.id
  tags   = { Name = "${var.name}-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
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
  vpc_id      = data.aws_vpc.target.id

  ingress {
    description = "SSH from Internet (required by assignment)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MongoDB from VPC only (Kubernetes network)"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.target.cidr_block] # 10.0.0.0/16
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
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.mongo_vm.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.mongo_vm_profile.name

  user_data = templatefile("${path.module}/userdata.sh.tftpl", {
    mongo_admin_user = var.mongo_admin_user
    mongo_admin_pass = var.mongo_admin_pass
    backup_bucket    = aws_s3_bucket.backups.bucket
  })

  tags = { Name = "${var.name}-mongo-vm" }
}