module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access = true

  vpc_id     = data.aws_vpc.target.id
  subnet_ids = local.eks_subnet_ids

  enable_irsa = true

  access_entries = {
    admin = {
      principal_arn = var.eks_admin_role_arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = [var.eks_node_instance_type]
      min_size       = var.eks_node_min_size
      max_size       = var.eks_node_max_size
      desired_size   = var.eks_node_desired_size
    }
  }
}
