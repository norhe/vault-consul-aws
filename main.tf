provider "aws" {
  region = "${var.region}"
}

# retrieve latest Ubuntu server
# See http://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
# for information on finding your preferred OS
data "aws_ami" "base_server" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# create a VPC for the POV
# https://registry.terraform.io/modules/terraform-aws-modules/vpc
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vault-pov-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  enable_vpn_gateway   = true

  tags {
    Terraform   = "true"
    Environment = "dev"
  }
}

# allow auto-join, vault AWS secret backend
resource "aws_iam_role" "pov_server" {
  name               = "pov-server"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "pov_server" {
  name   = "SelfAssembly"
  role   = "${aws_iam_role.pov_server.id}"
  policy = "${data.aws_iam_policy_document.pov_server.json}"
}

resource "aws_iam_instance_profile" "pov_server" {
  name = "pov-server"
  role = "${aws_iam_role.pov_server.name}"
}

## Machines
resource "aws_instance" "pov-server" {
  count         = "${var.cluster_size}"
  ami           = "${data.aws_ami.base_server.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${module.vpc.public_subnets[count.index]}"

  iam_instance_profile = "${aws_iam_instance_profile.pov_server.id}"

  vpc_security_group_ids = [
    "${aws_security_group.vault_pov_server.id}",
    "${aws_security_group.consul_client.id}",
  ]

  tags {
    Terraform     = "true"
    Environment   = "dev"
    consul_server = "true" # needed for Consul auto-join
  }

  associate_public_ip_address = true

  connection {
    user  = "${var.ssh_user}"
    private_key = "${var.private_key}"              # use ssh_agent, i.e. `ssh-add /path/to/key`
  }

  # upload necessary scripts
  provisioner "file" {
    source      = "./scripts/"
    destination = "/tmp"
  }

  # upload zips if proivded
  provisioner "file" {
    source      = "./binaries/"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod a+x /tmp/*.sh",
      "/tmp/setup-user.sh consul",
      "/tmp/setup-user.sh vault",
      "/tmp/base.sh",
      "/tmp/install-vault.sh",
      "/tmp/install-consul.sh",
      "/tmp/install-systemd-scripts.sh",
      "/tmp/install-configs-aws.sh ${var.cluster_size}",
      "sudo systemctl enable consul.service",
      "sudo systemctl start consul",
      "sudo systemctl enable vault.service",
      "sudo systemctl start vault",
    ]
  }
}
