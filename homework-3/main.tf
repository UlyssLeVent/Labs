terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
}

variable "ami_id" {
    type = string
    default = "ami-08e2d37b6a0129927"
    description = "Application and OS Image"
}

variable "ec2_instance" {
    type = string
    description = "Instance type"
    default = "t2.micro"
}

variable "key_pair" {
    description = "The EC2 KeyPair"
    type = string
    default = "lab-key"
}

resource "aws_iam_policy" "s3_policy" {
  name = "LabsS3GetObject"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3GetObject",
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "LabsEC2Role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  ingress {
    description      = "SSH from Word"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  ingress {
    description      = "HTTP from Word"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "Allow HTTPS inbound traffic"
  ingress {
    description      = "HTTP from Word"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


resource "aws_iam_policy_attachment" "ec2_policy_role" {
    name = "ec2_attachment"
    roles = [aws_iam_role.ec2_role.name]
    policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2_profile"
    role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.ec2_instance
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name = var.key_pair
  user_data = file("setup.sh")
  security_groups = [aws_security_group.allow_ssh.name, aws_security_group.allow_http.name]
}

output "instances" {
  value       = aws_instance.app_server.*.public_ip
  description = "PublicIP"
}

