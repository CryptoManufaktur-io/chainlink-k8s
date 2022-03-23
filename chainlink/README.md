# Infrastructure Management
This repository holds various Terraform scripts and modules that manages our infrastructure. Each component has a README for guidance/reference.

## CLI Requirements
[aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) >= 2.3.2 
[aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) >= 0.5.5 (optional)
[terraform cli](https://www.terraform.io/downloads) >= 1.1.7
## How to use
In order to replicate this for a total different environment please follow the steps below

1. Copy this directory into another directory and rename
2. Create  EC2  SSH Key Pair
This module expects an already existing ssh key pair for worker nodes and bastion host. This was done so that we dont care about the security implications of storing keys on the terraform state file. Please [see](https://docs.aws.amazon.com/ground-station/latest/ug/create-ec2-ssh-key-pair.html). Then note the name of the key(s) created as you will need to update this for the variables `bastion_key_name` and `worker_key_name`. 
3. Configure AWS CLI. See [this](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) to configure aws cli quickly and note your profile name

4. Configure the provider. Here changes are done on the provider.tf file
i. Change  region to the region you want to deploy changes and as well as the aws profile you created from the last step
```
provider "aws" {
  .
  .
  region  = "us-east-2" 
  profile = "crypto"
  .
}
```

ii. Change the backend source location to any location of your choice

```
terraform {
  .
  .
  .
  backend "s3" {
    bucket = "cryptomanufakturer-terraform-backend" #This is the name of the bucket to store the state
    region = "us-east-2" #The region of the bucket
    key = "chain-link/test/state.json" #The key name for the object
    profile = "crypto" #The AWS profile to use on your local for authenticating to the aws s3 api, this can be left empty if you are using the default profile
  }
}
```
5. Customize the infrastructure

For minimal deployment see below list of variables choices to  customize the vpc and eks deployment, for extra customizations you can find link to the respective modules readme on the Modules section to find other variables.
6. Initiliaze terraform 
To initiliaze terraform, cd into the root of this newly created directory and run
 ```
terraform init
 ```
If all goes well you should see below output in green

`Terraform has been successfully initialized!`

7. Plan changes
To  plan changes to see expected changes to your aws infrastructure, run below command
```
terraform plan
```
You should see a long list of changes and as well as the summary of changes 

`Plan: 72 to add, 0 to change, 0 to destroy.`

8. Apply changes
Once you are satisfied with the intended changes, you can now apply your changes by running below and follow the prompt by typing `yes`

```
terraform apply
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.74.3 |

Note: We use s3 to backup the state of terraform here, in this case an s3 of name cryptomanufakturer-terraform-backend with key chain-link/teststatejson, so just incase this needs to be replicated the s3 name or at least the key needs to change

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ../modules/bastion | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | github.com/CryptoManufaktur-io/terraform-aws-eks.git | v18.10.0 |
| <a name="module_iam_assumable_role_with_oidc"></a> [iam\_assumable\_role\_with\_oidc](#module\_iam\_assumable\_role\_with\_oidc) | ../modules/iam-assumable-role-with-oidc | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | github.com/CryptoManufaktur-io/terraform-aws-vpc.git | v3.13.0 |

## Resources

| Name | Type |
|------|------|
| [aws_kms_key.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_cidr"></a> [admin\_cidr](#input\_admin\_cidr) | CIDR pattern to access the bastion host | `string` | `"0.0.0.0/0"` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | A list of availability zones names or ids in the region | `list(string)` | <pre>[<br>  "us-east-2a",<br>  "us-east-2b",<br>  "us-east-2c"<br>]</pre> | no |
| <a name="input_bastion_key_name"></a> [bastion\_key\_name](#input\_bastion\_key\_name) | The key name that should be used for the bastion instance(s) | `string` | `null` | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden | `string` | `"10.21.0.0/16"` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Indicates whether or not the Amazon EKS private API server endpoint is enabled | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | `"chain-link"` | no |
| <a name="input_cluster_security_group_additional_rules"></a> [cluster\_security\_group\_additional\_rules](#input\_cluster\_security\_group\_additional\_rules) | List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source | `any` | <pre>{<br>  "one": {<br>    "cidr_blocks": [<br>      "10.21.0.0/16"<br>    ],<br>    "description": "Cluster API to VPC",<br>    "from_port": 443,<br>    "protocol": "tcp",<br>    "to_port": 443,<br>    "type": "egress"<br>  },<br>  "two": {<br>    "cidr_blocks": [<br>      "10.21.0.0/16"<br>    ],<br>    "description": "VPC to Cluster API",<br>    "from_port": 443,<br>    "protocol": "tcp",<br>    "to_port": 443,<br>    "type": "ingress"<br>  }<br>}</pre> | no |
| <a name="input_create_database_internet_gateway_route"></a> [create\_database\_internet\_gateway\_route](#input\_create\_database\_internet\_gateway\_route) | Controls if an internet gateway route for public database access should be created | `bool` | `false` | no |
| <a name="input_create_database_nat_gateway_route"></a> [create\_database\_nat\_gateway\_route](#input\_create\_database\_nat\_gateway\_route) | Controls if a nat gateway route should be created to give internet access to the database subnets | `bool` | `true` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Controls if database subnet group should be created (n.b. database\_subnets must also be set) | `bool` | `true` | no |
| <a name="input_database_subnets"></a> [database\_subnets](#input\_database\_subnets) | A list of database subnets | `list(string)` | <pre>[<br>  "10.21.21.0/24",<br>  "10.21.22.0/24",<br>  "10.21.23.0/24"<br>]</pre> | no |
| <a name="input_deletion_window_in_days"></a> [deletion\_window\_in\_days](#input\_deletion\_window\_in\_days) | The waiting period, specified in number of days. After the waiting period ends, AWS KMS deletes the KMS key. If you specify a value, it must be between 7 and 30, inclusive. | `number` | `10` | no |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Desired number of instances/nodes | `number` | `1` | no |
| <a name="input_eks_version"></a> [eks\_version](#input\_eks\_version) | n/a | `string` | `"1.21"` | no |
| <a name="input_enable_bastion"></a> [enable\_bastion](#input\_enable\_bastion) | If true the bastion will be created. Be default the bastion host is not running, needs explicit set to true. | `bool` | `true` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Should be true to enable DNS hostnames in the VPC | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Should be true to enable DNS support in the VPC | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Should be true if you want to provision NAT Gateways for each of your private networks | `bool` | `true` | no |
| <a name="input_encryption_config_resources"></a> [encryption\_config\_resources](#input\_encryption\_config\_resources) | List of strings with resources to be encrypted. Valid values: secrets | `list(any)` | <pre>[<br>  "secrets"<br>]</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Logical name of the environment. | `string` | `"test"` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | Set of instance types associated with the EKS Node Group. Defaults to `["t3.medium"]` | `list(string)` | `null` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of instances/nodes | `number` | `3` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of instances/nodes | `number` | `0` | no |
| <a name="input_node_security_group_additional_rules"></a> [node\_security\_group\_additional\_rules](#input\_node\_security\_group\_additional\_rules) | List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source | `any` | <pre>{<br>  "one": {<br>    "cidr_blocks": [<br>      "10.21.0.0/16"<br>    ],<br>    "description": "worker node to VPC ssh",<br>    "from_port": 22,<br>    "protocol": "tcp",<br>    "to_port": 22,<br>    "type": "egress"<br>  },<br>  "two": {<br>    "cidr_blocks": [<br>      "10.21.0.0/16"<br>    ],<br>    "description": "VPC to Woker ssh",<br>    "from_port": 22,<br>    "protocol": "tcp",<br>    "to_port": 22,<br>    "type": "ingress"<br>  }<br>}</pre> | no |
| <a name="input_nodegroup_name"></a> [nodegroup\_name](#input\_nodegroup\_name) | Name of the EKS managed node group | `string` | `""` | no |
| <a name="input_oidc_fully_qualified_subjects"></a> [oidc\_fully\_qualified\_subjects](#input\_oidc\_fully\_qualified\_subjects) | The fully qualified OIDC subjects to be added to the role policy | `set(string)` | <pre>[<br>  "system:serviceaccount:kube-system:ebs-csi-controller-sa"<br>]</pre> | no |
| <a name="input_private_subnet_tags"></a> [private\_subnet\_tags](#input\_private\_subnet\_tags) | Additional tags for the private subnets | `map(string)` | `{}` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | A list of private subnets inside the VPC | `list(string)` | <pre>[<br>  "10.21.1.0/24",<br>  "10.21.2.0/24",<br>  "10.21.3.0/24"<br>]</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | Name of the project. | `string` | `"chainlink"` | no |
| <a name="input_public_subnet_tags"></a> [public\_subnet\_tags](#input\_public\_subnet\_tags) | Additional tags for the public subnets | `map(string)` | `{}` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of public subnets inside the VPC | `list(string)` | <pre>[<br>  "10.21.4.0/24",<br>  "10.21.5.0/24",<br>  "10.21.6.0/24"<br>]</pre> | no |
| <a name="input_role_name_addon"></a> [role\_name\_addon](#input\_role\_name\_addon) | IAM role name for CSI AddOn | `string` | `"AmazonEKSEBSCSIRole"` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | <pre>{<br>  "Environment": "test",<br>  "Product": "chain-link",<br>  "Terraform": "true"<br>}</pre> | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name to be used on all the resources as identifier for VPC resources | `string` | `"chainlink-k8s"` | no |
| <a name="input_worker_key_name"></a> [worker\_key\_name](#input\_worker\_key\_name) | The key name that should be used for the worker node instance(s) | `string` | `null` | no |

## Outputs
| Name | Description |
|------|-------------|
| <a name="output_bastion_public_ip"></a> [bastion\_public\_ip](#output\_bastion\_public\_ip) | n/a |

<!-- END_TF_DOCS -->
