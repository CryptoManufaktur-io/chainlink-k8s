# Terraform bastion module

Module to create a bastion host (or stepping stone). The module let you enable this host once needed. Be default the host is not created.

## Example usages:
See also the [full examples](./examples).

```

module "vpc" {
  source = "git::https://github.com/philips-software/terraform-aws-vpc?ref=2.0.0"

  environment = var.environment
  aws_region  = var.aws_region
}

# Default bastion
module "bastion" {
  source = "git::https://github.com/philips-software/terraform-aws-bastion?ref=2.0.0"
  enable_bastion = true

  environment = var.environment
  project     = var.project

  aws_region = var.aws_region
  key_name   = aws_key_pair.bastion_key[0].key_name
  subnet_id  = element(module.vpc.public_subnets, 0)
  vpc_id     = module.vpc.vpc_id

  // add additional tags
  tags = {
    my-tag = "my-new-tag"
  }
}

```

## Inputs

| Name                    | Description                                                                                                  |    Type     |    Default    | Required |
| ----------------------- | ------------------------------------------------------------------------------------------------------------ | :---------: | :-----------: | :------: |
| admin\_cidr             | CIDR pattern to access the bastion host                                                                      |   string    | `"0.0.0.0/0"` |    no    |
| amazon\_optimized\_amis | Map from region to AMI. By default the latest Amazon Linux is used.                                          | map(string) |    `<map>`    |    no    |
| aws\_region             | The Amazon region.                                                                                           |   string    |      n/a      |   yes    |
| ebs\_optimized          | If true, the launched EC2 instance will be EBS-optimized.                                                    |    bool     |   `"false"`   |    no    |
| enable\_bastion         | If true the bastion will be created. Be default the bastion host is not running, needs explicit set to true. |    bool     |   `"false"`   |    no    |
| environment             | Logical name of the environment.                                                                             |   string    |      n/a      |   yes    |
| instance\_type          | EC2 instance type.                                                                                           |   string    | `"t2.micro"`  |    no    |
| key\_name               | SSH key name for the environment.                                                                            |   string    |      n/a      |   yes    |
| project                 | Name of the project.                                                                                         |   string    |      n/a      |   yes    |
| subnet\_id              | Subnet in which the basion needs to be deployed.                                                             |   string    |      n/a      |   yes    |
| tags                    | Map of tags to apply on the resources                                                                        | map(string) |    `<map>`    |    no    |
| user\_data              | Used data for bastion EC2 instance                                                                           |   string    |     `""`      |    no    |
| vpc\_id                 | The VPC to launch the instance in (e.g. vpc-66ecaa02).                                                       |   string    |      n/a      |   yes    |

## Outputs

| Name         | Description                        |
| ------------ | ---------------------------------- |
| instance\_id | Id of the created instance.        |
| public\_ip   | Public ip of the created instance. |
