variable "region" {
  description = "Which AWS region in which to deploy"
  default     = "us-east-1"
}

variable "cluster_size" {
  description = "How  many servers to deploy"
  default     = "3"
}

variable "instance_type" {
  description = "instance_type of deployed machines"
  default     = "t2.micro"
}

variable "key_name" {
  description = "The pre-existing SSH key to use to authenticate to the deployed VMs"
}

variable "ssh_user" {
  description = "Username for SSH connections used during provisioning."
}

variable "private_key" {
  description = "The contents of the private key"
}
# Outputs

output "vault-servers" {
  value = ["${aws_instance.pov-server.*.public_dns}"]
}
