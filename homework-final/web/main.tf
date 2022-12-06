variable "ami_id" {
    type = string
    default = "ami-08e2d37b6a0129927"
    description = "Application and OS Image"
}


variable "vpc" {
}

variable "subnets" {
}

variable "ec2_type" {
}

variable "key_pair" {
}

variable "policies" {
}

variable "setup_file" {
}


resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow inbound traffic"
  vpc_id      = var.vpc.id
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


resource "aws_iam_role" "web" {
  name = "WEBEC2Role"
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


resource "aws_iam_instance_profile" "homework" {
    name = "homework"
    role = aws_iam_role.web.name
}


resource "aws_iam_policy_attachment" "attach" {
    for_each = var.policies

    name = each.key
    roles= [aws_iam_role.web.name]
    policy_arn = each.value
}


resource "aws_lb_target_group" "http" {
  name     = "HTTP"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc.id
  health_check {
    path = "/health"
    port = 80
  }
}


resource "aws_security_group" "alb" {
  name        = "ALB-SG"
  description = "ALB"
  vpc_id      = var.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "web" {
    name = "web"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb.id]
    subnets = [for i, v in var.subnets: v.id]
    ip_address_type = "ipv4"
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.http.arn
    type             = "forward"
  }
}


resource "aws_launch_template" "web" {
  description = "Homework launch template: t2.micro with preinstalled java application"
  image_id      = var.ami_id
  instance_type = var.ec2_type
  key_name      = var.key_pair
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.homework.name
  }
  tags = {
      Name = "WEB"
      Environment = "homework"
  }
  user_data = filebase64(var.setup_file)
}


resource "aws_autoscaling_group" "web" {
  name = "web"
  max_size = 2
  min_size = 2
  health_check_type    = "ELB"
  vpc_zone_identifier  = [for i, v in var.subnets: v.id]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.http.arn]
}

output "dns_name" {
    value = aws_lb.web.dns_name
}
