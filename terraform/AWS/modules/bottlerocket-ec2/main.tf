provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "bottlerocket_image_id" {
  name = "/aws/service/bottlerocket/aws-k8s-1.24/x86_64/latest/image_id"
}

data "aws_ami" "bottlerocket_image" {
  owners = ["amazon"]
  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.bottlerocket_image_id.value]
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  user_data = <<-EOT
    [settings.host-containers.admin]
    enabled = true
  EOT
}

module "bottlerocket_ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "bottlerocket-instance"
  ami                    = data.aws_ami.bottlerocket_image.id
  instance_type          = "t2.small"

  create_iam_instance_profile = true
  iam_role_policies = {
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:poliouncy/AmazonSSMManagedInstanceCore"
  }
  #EPAM ONLY. PLEASE COMMENT THESE LINES
  iam_role_permissions_boundary = "arn:aws:iam::${local.account_id}:policy/eo_role_boundary"
  #END OF THE SECTION

  ebs_block_device = [
    {
      device_name = "/dev/xvdb"
      volume_type = "gp3"
      volume_size = 50
      throughput  = 200
      encrypted   = false
    }
  ]

  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true
}

output "instance_id" {
  value       = module.bottlerocket_ec2.id
}
