provider "aws" {
  region = var.region

  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.cluster_prefix}-${local.account_id}-model-bucket"
  acl    = "private"

  control_object_ownership = true
  force_destroy = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}
