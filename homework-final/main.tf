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


variable "ec2_type" {
    type = string
    description = "Instance type"
    default = "t2.micro"
}

variable "key_pair" {
    description = "The EC2 KeyPair"
    type = string
    default = "lab-key"
}

variable "bucket" {
}

module "subnets" {
    source = "./subnets"
}

module "bastion" {
    source = "./bastion"

    vpc = module.subnets.vpc
    ec2_type = var.ec2_type
    key_pair = var.key_pair
    cidr_blocks = [for i, v in module.subnets.private: v.cidr_block]
    subnet_id = module.subnets.public[0].id
    private = module.subnets.private
    depends_on = [module.subnets]
}


module "sns" {
    source = "./sns"

    topic = "edu-lohika-training-aws-sns-topic"
}


module "sqs" {
    source = "./sqs"

    queue = "edu-lohika-training-aws-sqs-queue"
}


module "ddb" {
    source = "./training-ddb"
}


module "rds" {
    source = "./training-rds"
    cidr_block = module.subnets.vpc.cidr_block
}


resource "aws_iam_policy" "s3" {
  name = "LabsS3Get"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3GetObject",
            "Effect": "Allow",
            "Action": "s3:Get*",
            "Resource": "*"
        }
    ]
  })
}


module "front" {
    source = "./web"

    vpc = module.subnets.vpc
    depends_on = [module.subnets]
    policies = {
        "sns-policy" = module.sns.policy.arn
        "sqs-policy" = module.sqs.policy.arn
        "ddb-policy" = module.ddb.policy.arn
        "s3-policy"  = aws_iam_policy.s3.arn
    }
    subnets = module.subnets.public
    setup_file = "setup-web.sh"
    ec2_type = var.ec2_type
    key_pair = var.key_pair
}


module "back" {
    source = "./back"

    vpc = module.subnets.vpc
    ami_id = var.ami_id
    subnet_id = module.subnets.private[0].id
    ec2_type = var.ec2_type
    key_pair = var.key_pair
    setup_file = "setup-back.sh"
}


output "rds_endpoint" {
    description = "RDS Endpoint"
    value = module.rds.endpoint
}


output "dns_name" {
    description = "DNS Name of a LB"
    value = module.front.dns_name
}
