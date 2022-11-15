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

module "sqs" {
    source = "./sqs"
}

module "sns" {
    source = "./sns"
}

module "ec2" {
    source = "./ec2"
    depends_on = [module.sqs, module.sns]
}

output "sqs" {
    value = module.sqs.url
    description = "The URL of SQS service"
}

output "sns" {
    value = module.sns.arn
    description = "The ARN of SNS service"
}

output "ec2" {
    value = module.ec2.public_ip
    description = "The Public IP of EC2 instance"
}
