module "vpc" {
  source = "github.com/CryptoManufaktur-io/terraform-aws-vpc.git?ref=v3.13.0"

  name = "chain-link"
  cidr = "10.21.0.0/16"

  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets = ["10.21.1.0/24", "10.21.2.0/24", "10.21.3.0/24"]
  public_subnets  = ["10.21.4.0/24", "10.21.5.0/24", "10.21.6.0/24"]
  database_subnets    = ["10.21.21.0/24", "10.21.22.0/24","10.21.23.0/24"]
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true
  single_nat_gateway = true
  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  //enable_vpn_gateway = true
  private_subnet_tags = {
    "kubernetes.io/cluster/chain-link-k8s" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
  
  public_subnet_tags = {
    "kubernetes.io/cluster/chain-link-k8s" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
  tags = {
    Terraform = "true"
    Environment = "test"
    Product   = "chain-link"
  }
}


resource "aws_kms_key" "eks" {
  description             = "KMS key for Encrypting EKS secrets"
  deletion_window_in_days = 10
}

module "eks" {
  source = "github.com/CryptoManufaktur-io/terraform-aws-eks.git?ref=v18.10.0"
  cluster_security_group_additional_rules = {one = {
      description                = "Cluster API to VPC"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "egress"
      cidr_blocks                = ["10.21.0.0/16"]
  },
  two = {
      description                = "VPC to Cluster API"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      cidr_blocks                = ["10.21.0.0/16"]
  }}
  node_security_group_additional_rules = {
      one = {
      description                = "worker node to VPC ssh"
      protocol                   = "tcp"
      from_port                  = 22
      to_port                    = 22
      type                       = "egress"
      cidr_blocks                = ["10.21.0.0/16"]
  },
  two = {
      description                = "VPC to Woker ssh"
      protocol                   = "tcp"
      from_port                  = 22
      to_port                    = 22
      type                       = "ingress"
      cidr_blocks                = ["10.21.0.0/16"]
  }}

  cluster_name                    = "chain-link"
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
    resources        = ["secrets"]
  }]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    one = {
      instance_types = ["m6i.large"]
      name = "chain-link-k8s-worker"
      key_name  = "test"
      public_ip    = false
      max_size     = 5
      desired_size = 3
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


  
  tags = {
    Environment = "test"
    Terraform   = "true"
    App         = "chainlink"
  }
}
// When running openebs this should be commented out as it isnt needed 
module "iam_assumable_role_with_oidc" {
  source = "../modules/iam-assumable-role-with-oidc"
  //version = "~> 2.0"

  create_role = true

  role_name = "AmazonEKSEBSCSIRole"

  tags = {
    Role = "AmazonEKSEBSCSIRole"
  }

  provider_url = module.eks.oidc_provider
  oidc_fully_qualified_subjects = [ "system:serviceaccount:kube-system:ebs-csi-controller-sa"]

  role_policy_arns = [
    # "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]
}
