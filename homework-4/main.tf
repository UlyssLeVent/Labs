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

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "subnet-2a" {
  availability_zone = "us-west-2a"
  tags = {
    Name = "Default subnet for us-west-2a"
  }
}

resource "aws_default_subnet" "subnet-2b" {
  availability_zone = "us-west-2b"
  tags = {
    Name = "Default subnet for us-west-2b"
  }
}

resource "aws_default_subnet" "subnet-2c" {
  availability_zone = "us-west-2c"
  tags = {
    Name = "Default subnet for us-west-2c"
  }
}

resource "aws_default_subnet" "subnet-2d" {
  availability_zone = "us-west-2d"
  tags = {
    Name = "Default subnet for us-west-2d"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet"
  subnet_ids = [aws_default_subnet.subnet-2a.id, aws_default_subnet.subnet-2b.id, aws_default_subnet.subnet-2c.id, aws_default_subnet.subnet-2d.id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_security_group" "allow_postgres" {
  name        = "allow_postgres"
  description = "Allow Postgres inbound traffic"

  ingress {
    description      = "Postgres"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = [aws_default_vpc.default.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  allocated_storage = 20
  engine = "postgres"
  engine_version = "13.7"
  instance_class = "db.t3.micro"
  db_subnet_group_name    = aws_db_subnet_group.rds.id
  username = "master"
  password = "duss-smek-bun"
  publicly_accessible = false
  storage_encrypted   = false
  skip_final_snapshot = true
  max_allocated_storage = 0

  vpc_security_group_ids = [aws_security_group.allow_postgres.id]
}

resource "aws_dynamodb_table" "homework" {
  name           = "Devices"
  hash_key       = "Type"
  read_capacity  = 5
  write_capacity = 1

  attribute {
    name = "Type"
    type = "S"
  }
}

resource "aws_iam_policy" "dd_policy" {
  name = "LabsDynamoPolicy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DynamoDBAllow",
            "Effect": "Allow",
            "Action": "dynamodb:*",
            "Resource": "*"
        }
    ]
  })
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
  name = "LabsS3Policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectAttributes"
            ],
            "Resource": "arn:aws:s3:::*/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::*"
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

resource "aws_security_group" "allow_word" {
  name        = "allow_word"
  description = "Allow inbound traffic"
  ingress {
    description      = "SSH from Word"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP from Word"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTPS from Word"
    from_port        = 443
    to_port          = 443
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

resource "aws_iam_policy_attachment" "s3_attach" {
    name = "s3_attachment"
    roles = [aws_iam_role.ec2_role.name]
    policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_policy_attachment" "dd_attach" {
    name = "dd_attachment"
    roles = [aws_iam_role.ec2_role.name]
    policy_arn = aws_iam_policy.dd_policy.arn
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
  user_data = <<EOF
#!/bin/sh
aws s3 cp s3://gene-homework-4.dekis.org/dynamodb-script.sh ~ec2-user/
aws s3 cp s3://gene-homework-4.dekis.org/rds-script.sql ~ec2-user/
sudo yum -y install postgresql.x86_64  > ~ec2-user/yum.out 2> ~ec2-user/yum.err
EOF
  security_groups = [aws_security_group.allow_word.name]
}

output "instances" {
  value       = aws_instance.app_server.public_ip
  description = "PublicIP"
}

output "endpoint" {
 value       = aws_db_instance.postgres.endpoint
 description = "RDS Endpoint"
}

