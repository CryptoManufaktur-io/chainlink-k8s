locals {
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

module "vpc" {
  source = "github.com/CryptoManufaktur-io/terraform-aws-vpc.git?ref=v3.13.0"

  name = var.vpc_name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  database_subnets    = var.database_subnets
  create_database_subnet_group           = var.create_database_subnet_group
  create_database_subnet_route_table     = var.create_database_nat_gateway_route 
  create_database_internet_gateway_route = var.create_database_internet_gateway_route
  single_nat_gateway = var.single_nat_gateway
  enable_nat_gateway = var.enable_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  private_subnet_tags = merge(var.private_subnet_tags,local.private_subnet_tags)
  
  public_subnet_tags = merge(var.public_subnet_tags,local.public_subnet_tags)
  tags = var.tags
}


resource "aws_kms_key" "eks" {
  description             = "KMS key for Encrypting EKS secrets"
  deletion_window_in_days = var.deletion_window_in_days
}

module "eks" {
  source = "github.com/CryptoManufaktur-io/terraform-aws-eks.git?ref=v18.10.0"
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules
  node_security_group_additional_rules = var.node_security_group_additional_rules

  cluster_name                    = var.cluster_name
  cluster_version                 = var.eks_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    // When running openebs the aws-ebs-csi-driver addon should be commented
    aws-ebs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
      service_account_role_arn = module.iam_assumable_role_with_oidc.this_iam_role_arn
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  cluster_encryption_config = [{
    provider_key_arn = "${aws_kms_key.eks.arn}"
    resources        = var.encryption_config_resources
  }]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    one = {
      instance_types = var.instance_types
      name = var.nodegroup_name
      key_name  = var.worker_key_name
      public_ip    = false
      max_size     = var.max_size
      desired_size = var.desired_size
      min_size = var.min_size
      //When running openebs we need extra volumes, so this should be uncommented
      block_device_mappings = [
        # { 

        #   device_name = "/dev/sdb"
        #   virtual_name = "/dev/xvdb"
        #   delete_on_termination = false
        #   ebs = [
        #     { 
        #       volume_type = "gp2"
        #       volume_size = "20"
        #       }
        #   ]
        # },
        # {
        #   device_name = "/dev/sdc"
        #   virtual_name = "/dev/xvdc"
        #   delete_on_termination = false
        #   ebs = [
        #     { 
        #       volume_type = "gp2"
        #       volume_size = "20"
        #       }
        #   ]
        # }
    ]
      
    //  When running openebs we need to automount the volumes to the  linux fs, so this should be uncommented
      # pre_bootstrap_user_data = <<-EOT
      #   #!/bin/bash
      #   echo Starting
      #   set -x
      #   sudo mkfs -t xfs /dev/nvme1n1
      #   sudo mkdir /data
      #   sudo mount /dev/nvme1n1 /data
      #   id=$(blkid|grep nvme1n1|cut -d " " -f 2|cut -d "=" -f 2)
      #   echo "UUID=$${id:1:-1}  /data  xfs  defaults,nofail  0  2" >> /etc/fstab
      #   sudo mkfs -t xfs /dev/nvme2n1
      #   sudo mkdir /datac
      #   sudo mount /dev/nvme2n1 /datac
      #   id=$(blkid|grep nvme2n1|cut -d " " -f 2|cut -d "=" -f 2)
      #   echo "UUID=$${id:1:-1}     /datac  xfs  defaults,nofail  0  2" >> /etc/fstab
      #   yum -y install iscsi-initiator-utils
      #   systemctl enable --now iscsid

      #  EOT
    }
  }
  tags = var.tags
}


// When running openebs this should be commented out as it isnt needed 
module "iam_assumable_role_with_oidc" {
  source = "../modules/iam-assumable-role-with-oidc"
  //version = "~> 2.0"

  create_role = true

  role_name = var.role_name_addon

  tags = {
    Role = var.role_name_addon
  }

  provider_url = module.eks.oidc_provider
  oidc_fully_qualified_subjects = var.oidc_fully_qualified_subjects
}


#### Bastion
module "bastion" {
  source = "../modules/bastion"
  enable_bastion = var.enable_bastion

  environment = var.environment
  project     = var.project
  key_name   = var.bastion_key_name
  subnet_id  = element(module.vpc.private_subnets, 0)
  vpc_id     = module.vpc.vpc_id

}
