module "instance" {
  source         = "../modules/bottlerocket-ec2"
  region         = var.region
}


output "instance_id" {
  value       = "export INSTANCE_ID=${module.instance.instance_id}"
  description = "Instance ID export command"
}
