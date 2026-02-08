# CI-only defaults for terraform validate
vpc_id              = "vpc-0123456789abcdef0"
public_subnet_az    = "us-east-1a"
key_name            = "ci-key"
mongo_admin_pass    = "ci-pass-123"
app_name            = "ci-app"
environment         = "lab"
business_unit       = "ci-bu"
cost_center         = "ci-cc"
owner_business      = "ci-owner-biz"
owner_technical     = "ci-owner-tech"
data_classification = "internal"
eks_admin_role_arns = ["arn:aws:iam::123456789012:role/ci-eks-admin"]
