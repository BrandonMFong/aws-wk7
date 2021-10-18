# Author: Brando 

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.59.0"
    }
  }

  backend "s3" {
    bucket = "ece592-automation-brando"
    key    = "state.week7"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "default" # From a ~/.aws/credentials file.
}

# VPC
resource "aws_vpc" "week5-automation-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "week5-automation-vpc"
  }
}

# Subnets 

# Subnet 1
resource "aws_subnet" "week5-automation-sub-a" {
  vpc_id                  = aws_vpc.week5-automation-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "week5-automation-sub-a"
  }
}

# Subnet 2
resource "aws_subnet" "week5-automation-sub-b" {
  vpc_id                  = aws_vpc.week5-automation-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "week5-automation-sub-b"
  }
}

# Internet Gate Way 
resource "aws_internet_gateway" "week5-automation-igw" {
  vpc_id = aws_vpc.week5-automation-vpc.id

  tags = {
    Name = "week5-automation-igw"
  }
}

# Route Table
resource "aws_route_table" "week5-automation-rt" {
  vpc_id = aws_vpc.week5-automation-vpc.id

  route = [{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.week5-automation-igw.id

    # Values suggested by professor
    egress_only_gateway_id    = ""
    instance_id               = ""
    ipv6_cidr_block           = ""
    nat_gateway_id            = ""
    network_interface_id      = ""
    transit_gateway_id        = ""
    vpc_endpoint_id           = ""
    vpc_peering_connection_id = ""

    # Values suggested by the validate process
    # Investigate these values if there is an issue
    # with our config 
    carrier_gateway_id         = ""
    destination_prefix_list_id = ""
    local_gateway_id           = ""
  }, ]

  tags = {
    Name = "week5-automation-rt"
  }
}

# Security Group
resource "aws_security_group" "week5-automation-ssh-sg" {
  name        = "week4_ssh_sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.week5-automation-vpc.id

  ingress = [{
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    # Suggested by professor
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  egress = [{
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

    # Suggested
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  tags = {
    Name = "week5-automation-ssh-sg"
  }
}

# EC2
resource "aws_instance" "week5-automation-vm" {
  ami                  = data.aws_ami.latest-ubuntu.id
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.week5-automation-sub-a.id
  iam_instance_profile = aws_iam_instance_profile.automation-profile.name

  vpc_security_group_ids = [
    aws_security_group.week5-automation-ssh-sg.id
  ]

  key_name = "ECE592"

  tags = {
    Name = "week7"
  }
}

# AMI ref
data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

# IAM profile ref
resource "aws_iam_instance_profile" "automation-profile" {
  name = "week7-automation-profile"
  role = aws_iam_role.automation-role.name
  tags = {}
}

## SSE-KMS 
#resource "aws_kms_key" "week6-kms-v2" {}

#resource "aws_kms_alias" "week6-kms-v2" {
#  name          = "alias/week6-kms-v2"
#  target_key_id = aws_kms_key.week6-kms-v2.key_id
#}
