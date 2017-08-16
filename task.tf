provider "aws" {
  access_key = "AKIAJPPU3RFVZ3BPPZSA"
  secret_key = "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"
  region     = "us-west-1"
}

terraform {
  provider = "aws"
  backend "s3" {
    bucket = "stakater-training-remote-state-2"
    key = "task.tfstate"
    region = "us-west-1"
  }
}

data "aws_ami" "coreos_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*CoreOS*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }
}

data "aws_availability_zones" "az" {}

output "ami_image_id" {
  value = "${data.aws_ami.coreos_ami.image_id}"
}

output "az" {
  value = "${data.aws_availability_zones.az.names}"
}

resource "aws_security_group" "alpine_nginx_security_group" {
  name        = "alpine_nginx_security_group"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami = "${data.aws_ami.coreos_ami.id}"
  instance_type = "t2.nano"
  availability_zone = "${data.aws_availability_zones.az.names[0]}"
  security_groups = ["${aws_security_group.alpine_nginx_security_group.name}"]
  user_data = "${file("cloud-config.yml")}"
  key_name   = "stakater"

  tags {
    Name = "stakater_instance"
  }
}
