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
    bucket = "cryptomanufakturer-terraform-backend"
    region = "us-east-2"
    key = "chain-link/test/state.json"
    profile = "crypto"
  }
  
}
