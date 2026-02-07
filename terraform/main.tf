############################
data "aws_caller_identity" "current" {}

############################
# Public Subnet (use existing)
############################
locals {
  alb_subnet_ids = module.vpc.public_subnets
  eks_subnet_ids = module.vpc.private_subnets
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
    cidr_blocks = ["76.170.1.247/32"]
  }

  ingress {
    description = "MongoDB from VPC only (Kubernetes network)"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block] # 10.0.0.0/16
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-mongo-vm-sg" }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-sg-"
  description = "Public HTTP for WAF test ALB"
  vpc_id      = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-alb-sg" }
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

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.mongo_vm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "mongo_vm_profile" {
  name = "${var.name}-mongo-vm-profile"
  role = aws_iam_role.mongo_vm_role.name
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.name}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = 30
}

resource "aws_flow_log" "vpc" {
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id
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

resource "aws_lb" "waf" {
  name_prefix        = "waf-"
  load_balancer_type = "application"
  subnets            = local.alb_subnet_ids
  security_groups    = [aws_security_group.alb.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "waf_http" {
  load_balancer_arn = aws_lb.waf.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "waf test"
      status_code  = "200"
    }
  }
}

resource "aws_wafv2_web_acl" "main" {
  name  = "${var.name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "managed-common-rule-set"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "managed-common-rule-set"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "count-all"
    priority = 2
    action {
      count {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "count-all"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.waf.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

resource "random_string" "waf_logs_suffix" {
  count   = var.waf_logging_enabled ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "waf_logs" {
  count         = var.waf_logging_enabled ? 1 : 0
  bucket        = "${var.name}-waf-logs-${random_string.waf_logs_suffix[0].result}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  count                  = var.waf_logging_enabled ? 1 : 0
  bucket                 = aws_s3_bucket.waf_logs[0].id
  block_public_acls      = true
  block_public_policy    = true
  ignore_public_acls     = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "waf_firehose" {
  count = var.waf_logging_enabled ? 1 : 0
  name  = "${var.name}-waf-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "firehose.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "waf_firehose" {
  count = var.waf_logging_enabled ? 1 : 0
  name  = "${var.name}-waf-firehose-policy"
  role  = aws_iam_role.waf_firehose[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.waf_logs[0].arn,
          "${aws_s3_bucket.waf_logs[0].arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "${aws_cloudwatch_log_group.waf_firehose[0].arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "waf_firehose" {
  count             = var.waf_logging_enabled ? 1 : 0
  name              = "/aws/kinesisfirehose/aws-waf-logs-${var.name}"
  retention_in_days = 30
}

resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  count       = var.waf_logging_enabled ? 1 : 0
  name        = "aws-waf-logs-${var.name}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.waf_firehose[0].arn
    bucket_arn = aws_s3_bucket.waf_logs[0].arn

    buffering_size     = 5
    buffering_interval = 300
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.waf_firehose[0].name
      log_stream_name = "s3-delivery"
    }
  }

  depends_on = [aws_s3_bucket_public_access_block.waf_logs]
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count                  = var.waf_logging_enabled ? 1 : 0
  resource_arn           = aws_wafv2_web_acl.main.arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs[0].arn]
}

resource "aws_guardduty_detector" "main" {
  count  = var.manage_guardduty ? 1 : 0
  enable = true
}

resource "aws_detective_graph" "main" {
  count = var.manage_detective ? 1 : 0
}

resource "aws_securityhub_account" "main" {
  count = var.manage_securityhub ? 1 : 0
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count         = var.manage_securityhub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${var.region}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

resource "aws_securityhub_standards_subscription" "cis_1_4" {
  count         = var.manage_securityhub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${var.region}::standards/cis-aws-foundations-benchmark/v/1.4.0"
}

resource "aws_securityhub_product_subscription" "guardduty" {
  count       = var.manage_securityhub_subscriptions ? 1 : 0
  product_arn = "arn:aws:securityhub:${var.region}::product/aws/guardduty"

  depends_on = [aws_securityhub_account.main]
}

resource "aws_securityhub_product_subscription" "inspector" {
  count       = var.manage_securityhub_subscriptions ? 1 : 0
  product_arn = "arn:aws:securityhub:${var.region}::product/aws/inspector"

  depends_on = [aws_securityhub_account.main]
}

resource "aws_securityhub_product_subscription" "config" {
  count       = var.manage_securityhub_subscriptions ? 1 : 0
  product_arn = "arn:aws:securityhub:${var.region}::product/aws/config"

  depends_on = [aws_securityhub_account.main]
}

resource "aws_sns_topic" "securityhub_findings" {
  count = (var.manage_securityhub || var.manage_securityhub_subscriptions) ? 1 : 0
  name  = "${var.name}-securityhub-findings"
}

resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  count       = (var.manage_securityhub || var.manage_securityhub_subscriptions) ? 1 : 0
  name        = "${var.name}-securityhub-findings"
  description = "Forward Security Hub findings to SNS"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"],
    detail-type = ["Security Hub Findings - Imported"]
  })
}

resource "aws_cloudwatch_event_target" "securityhub_to_sns" {
  count = (var.manage_securityhub || var.manage_securityhub_subscriptions) ? 1 : 0
  rule  = aws_cloudwatch_event_rule.securityhub_findings[0].name
  arn   = aws_sns_topic.securityhub_findings[0].arn
}

resource "aws_sns_topic_policy" "securityhub_findings" {
  count = (var.manage_securityhub || var.manage_securityhub_subscriptions) ? 1 : 0
  arn   = aws_sns_topic.securityhub_findings[0].arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowEventBridgePublish",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action   = "sns:Publish",
        Resource = aws_sns_topic.securityhub_findings[0].arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.securityhub_findings[0].arn
          }
        }
      }
    ]
  })
}

resource "aws_inspector2_enabler" "main" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR"]
}

############################
# CloudTrail (multi-region)
############################
resource "random_string" "cloudtrail_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.name}-cloudtrail-${random_string.cloudtrail_suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid = "AWSCloudTrailAclCheck"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
  }

  statement {
    sid = "AWSCloudTrailWrite"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = var.cloudtrail_is_organization_trail ? ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${var.cloudtrail_org_id}/*"] : ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count             = var.cloudtrail_enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/cloudtrail/${var.name}"
  retention_in_days = var.cloudtrail_log_retention_days
}

resource "aws_iam_role" "cloudtrail" {
  count = var.cloudtrail_enable_cloudwatch_logs ? 1 : 0
  name  = "${var.name}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "cloudtrail.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail" {
  count = var.cloudtrail_enable_cloudwatch_logs ? 1 : 0
  name  = "${var.name}-cloudtrail-logs-policy"
  role  = aws_iam_role.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
    }]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "${var.name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = var.cloudtrail_is_organization_trail
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn     = var.cloudtrail_enable_cloudwatch_logs ? "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*" : null
  cloud_watch_logs_role_arn      = var.cloudtrail_enable_cloudwatch_logs ? aws_iam_role.cloudtrail[0].arn : null

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

############################
# AWS Config
############################
resource "random_string" "config_suffix" {
  count   = var.manage_config ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "config" {
  count         = var.manage_config ? 1 : 0
  bucket        = "${var.name}-config-${random_string.config_suffix[0].result}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "config" {
  count                   = var.manage_config ? 1 : 0
  bucket                  = aws_s3_bucket.config[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "config_bucket" {
  count = var.manage_config ? 1 : 0
  statement {
    sid = "AWSConfigAclCheck"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.config[0].arn]
  }

  statement {
    sid = "AWSConfigWrite"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.config[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "config" {
  count  = var.manage_config ? 1 : 0
  bucket = aws_s3_bucket.config[0].id
  policy = data.aws_iam_policy_document.config_bucket[0].json

  depends_on = [aws_s3_bucket_public_access_block.config]
}

resource "aws_iam_role" "config" {
  count = var.manage_config ? 1 : 0
  name  = "${var.name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "config.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "config" {
  count = var.manage_config ? 1 : 0
  name  = "${var.name}-config-policy"
  role  = aws_iam_role.config[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "config:Put*",
          "config:Get*",
          "config:List*",
          "config:Describe*",
          "config:BatchGet*",
          "config:Deliver*"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetBucketAcl", "s3:ListBucket"],
        Resource = [aws_s3_bucket.config[0].arn]
      },
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = ["${aws_s3_bucket.config[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"],
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = ["cloudwatch:PutMetricData"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_config_configuration_recorder" "main" {
  count    = var.manage_config ? 1 : 0
  name     = "${var.name}-config"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  count          = var.manage_config ? 1 : 0
  name           = "${var.name}-config"
  s3_bucket_name = aws_s3_bucket.config[0].bucket

  depends_on = [aws_s3_bucket_policy.config]
}

resource "aws_config_configuration_recorder_status" "main" {
  count      = var.manage_config ? 1 : 0
  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

############################
# EC2: Mongo VM
############################
resource "aws_instance" "mongo" {
  ami                         = data.aws_ami.debian10.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
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