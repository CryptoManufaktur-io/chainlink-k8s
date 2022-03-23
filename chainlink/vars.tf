variable "eks_version" {
    type = string
    default = "1.21"  
}

variable "vpc_name" {
  description = "Name to be used on all the resources as identifier for VPC resources"
  type        = string
  default     = "chainlink-k8s"
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.21.0.0/16"
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = ["10.21.1.0/24", "10.21.2.0/24", "10.21.3.0/24"]
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = ["10.21.4.0/24", "10.21.5.0/24", "10.21.6.0/24"]
}

variable "database_subnets" {
  description = "A list of database subnets"
  type        = list(string)
  default     =  ["10.21.21.0/24", "10.21.22.0/24","10.21.23.0/24"]
}


variable "create_database_internet_gateway_route" {
  description = "Controls if an internet gateway route for public database access should be created"
  type        = bool
  default     = false
}

variable "create_database_nat_gateway_route" {
  description = "Controls if a nat gateway route should be created to give internet access to the database subnets"
  type        = bool
  default     = true
}


variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}


variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}


variable "public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Terraform = "true"
    Environment = "test"
    Product   = "chain-link"
  }
}


variable "create_database_subnet_group" {
  description = "Controls if database subnet group should be created (n.b. database_subnets must also be set)"
  type        = bool
  default     = true
}


variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = true
}

variable "deletion_window_in_days" {
    default = 10
    type = number
    description = " The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the KMS key. If you specify a value, it must be between 7 and 30, inclusive. " 
}


variable "cluster_security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source"
  type        = any
  default     = {one = {
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
}

variable "node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source"
  type        = any
  default     = {
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
}

################################################################################
# EKS  Cluster
################################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "chain-link"
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "encryption_config_resources" {
    default = ["secrets"]
    type = list(any)
    description = "List of strings with resources to be encrypted. Valid values: secrets"
}


variable "instance_types" {
  description = "Set of instance types associated with the EKS Node Group. Defaults to `[\"t3.medium\"]`"
  type        = list(string)
  default     = null
}

variable "worker_key_name" {
  description = "The key name that should be used for the worker node instance(s)"
  type        = string
  default     = null
}


variable "nodegroup_name" {
  description = "Name of the EKS managed node group"
  type        = string
  default     = ""
}

variable "min_size" {
  description = "Minimum number of instances/nodes"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of instances/nodes"
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "Desired number of instances/nodes"
  type        = number
  default     = 1
}

variable "role_name_addon" {
  description = "IAM role name for CSI AddOn"
  type        = string
  default     = "AmazonEKSEBSCSIRole"
}


variable "oidc_fully_qualified_subjects" {
  description = "The fully qualified OIDC subjects to be added to the role policy"
  type        = set(string)
  default     = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}


################################################################################
# Bastion
################################################################################

variable "admin_cidr" {
  description = "CIDR pattern to access the bastion host"
  type        = string
  default     = "0.0.0.0/0"
}

variable "environment" {
  description = "Logical name of the environment."
  type        = string
  default     = "test"
}

variable "project" {
  description = "Name of the project."
  type        = string
  default     = "chainlink"
}


variable "enable_bastion" {
  description = "If true the bastion will be created. Be default the bastion host is not running, needs explicit set to true."
  type        = bool
  default     = true
}

variable "bastion_key_name" {
  description = "The key name that should be used for the bastion instance(s)"
  type        = string
  default     = null
}
