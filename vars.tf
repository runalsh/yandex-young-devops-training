#====VARS ========================
variable "region" {
  default = "eu-central-1"
  type    = string
}

variable "prefix" {
  type    = string
}

variable "studentemail" {
  type    = string
}

variable "lb_instance_type" {
  type    = string
}

variable "dbpassword" {
  type    = string
}
variable "dbname" {
  type    = string
}
variable "dbuser" {
  type    = string
}

variable "domain" {
  type    = string
}
variable "app_instance_type" {
  type    = string
}
variable "app_desired_intsances" {
  type    = string
}
variable "app_minimum_instances" {
  type    = string
}
variable "app_maximum_instances" {
  type    = string
}

variable "db_ec2instance_type" {
  type    = string
}

variable "public_subnets" {
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

data "aws_ami" "debian" {
  most_recent = true
  owners = ["136693071363"]
  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
