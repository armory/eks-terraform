#
# Provider Configuration
#

provider "aws" {
  version = "~> 1.42.0"
  region = "us-west-2"
  profile = "MY_AWS_PROFILE"
}

# Using these data sources allows the configuration to be
# generic for any region.
data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

# Not required: currently used in conjuction with using
# icanhazip.com to determine local workstation external IP
# to open EC2 Security Group access to the Kubernetes cluster.
# See workstation-external-ip.tf for additional information.
provider "http" {}

terraform {
  backend "s3" {
    bucket = "BUCKET_NAME"
    key    = "KEY_NAME"
    region = "us-west-2"
    profile = "MY_AWS_PROFILE"
  }
}
