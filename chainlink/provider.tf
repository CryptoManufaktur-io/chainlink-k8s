provider "aws" {
  region  = "us-east-2"
  version = "~> 3.0"
  profile = "crypto"

}

# provider "kubernetes" {
#   config_path = "~/.kube/sandbox_kubeconfig"
# }

terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.0.2"
    }
  }
  backend "s3" {
    bucket = "cryptomanufakturer-terraform-backend"  #This is the name of the bucket to store the state
    region = "us-east-2" #The region of the bucket
    key = "chain-link/test/state.json" #The key name for the object
    profile = "crypto" #The AWS profile to use on your local for authenticating to the aws s3 api
  }
  
}
