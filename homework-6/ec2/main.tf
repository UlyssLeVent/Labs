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

resource "aws_security_group" "allow_word" {
  name        = "allow_word"
  description = "Allow inbound traffic"
  #vpc_id      = aws_vpc.homework.id
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
  }
}


resource "aws_iam_role" "ec2_role" {
  name = "LabsEC2Role"
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

resource "aws_iam_policy" "sqs" {
  name = "SQSPolicy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SQSPolicy",
            "Effect": "Allow",
            "Action": "sqs:*",
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_policy" "sns" {
  name = "SNSPolicy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SNSPolicy",
            "Effect": "Allow",
            "Action": "sns:*",
            "Resource": "*"
        }
    ]
  })
}


#resource "aws_iam_policy_attachment" "s3_attach" {
#    name = "s3_attachment"
#    roles = [aws_iam_role.ec2_role.name]
#    policy_arn = aws_iam_policy.s3_policy.arn
#}

resource "aws_iam_policy_attachment" "sqs" {
    name = "sqs_attachment"
    roles = [aws_iam_role.ec2_role.name]
    policy_arn = aws_iam_policy.sqs.arn
}

resource "aws_iam_policy_attachment" "sns" {
    name = "sns_attachment"
    roles = [aws_iam_role.ec2_role.name]
    policy_arn = aws_iam_policy.sns.arn
}

resource "aws_iam_instance_profile" "homework" {
    name = "homework"
    role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.ec2_instance
  key_name = var.key_pair
  vpc_security_group_ids = [aws_security_group.allow_word.id]
  iam_instance_profile = aws_iam_instance_profile.homework.name
  tags = {
      Name = "Public instance"
  }
  user_data = <<-EOF
#!/bin/sh
exec 2> /tmp/setup.log
sudo yum -y update
EOF
}

output "public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "PublicIP"
}


