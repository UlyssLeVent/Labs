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

resource "aws_vpc" "homework" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "LabVPC"
  }
}


resource "aws_internet_gateway" "homework" {
  vpc_id = aws_vpc.homework.id
  tags = {
    Name = "LabGW"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.homework.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a"

  tags = {
    Name = "Public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.homework.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "Private"
  }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.homework.id

#  route {
#    cidr_block = "10.0.0.0/26"
#  }

  route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.homework.id
  }

  tags = {
    Name = "Public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id #
  route_table_id = aws_route_table.public.id
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

resource "aws_security_group" "allow_word" {
  name        = "allow_word"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.homework.id
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

resource "aws_security_group" "allow_nat" {
  name        = "allow_nat"
  description = "Allow NAT traffic"
  vpc_id      = aws_vpc.homework.id
  ingress {
    description      = "SSH from Word"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP from Private"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.private.cidr_block]
  }
  ingress {
    description      = "HTTPS from Private"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.private.cidr_block]
  }
  egress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.ec2_instance
  key_name = var.key_pair
  associate_public_ip_address  = true
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_word.id]
  tags = {
      Name = "Public instance"
  }
  user_data = <<-EOF
#!/bin/sh
exec 2> /tmp/setup.log
sudo yum -y update
sudo yum -y install httpd
sudo systemctl start httpd
sudo echo '<html><head><title>Public Page</title></head><body><h1>On Public</h1></body>' > /var/www/html/index.html
EOF
}

resource "aws_network_interface" "nat_iface" {
  subnet_id = aws_subnet.public.id
  source_dest_check = false
  security_groups = [aws_security_group.allow_nat.id]

  tags = {
    Name = "nat_instance_network_interface"
  }
}

resource "aws_instance" "nat_server" {
  ami           = "ami-0bc50b53fc59f31e0"
  instance_type = var.ec2_instance
  key_name = var.key_pair
  network_interface {
    network_interface_id = aws_network_interface.nat_iface.id
    device_index = 0
  }
  tags = {
      Name = "NAT instance"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.homework.id

  route {
   cidr_block = "0.0.0.0/0"
   network_interface_id = aws_network_interface.nat_iface.id
  }

  tags = {
    Name = "Private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_instance" "private_server" {
  ami           = var.ami_id
  instance_type = var.ec2_instance
  key_name = var.key_pair
  associate_public_ip_address  = false
  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.allow_word.id]
  depends_on = [aws_instance.nat_server, aws_route_table_association.private]
  tags = {
      Name = "Private instance"
  }
  user_data = <<-EOF
#!/bin/sh
exec 2> /tmp/setup.log
sudo yum -y update
sudo yum -y install httpd
sudo systemctl start httpd
sudo echo '<html><head><title>Private Page</title></head><body><h1>On Private</h1></body>' > /var/www/html/index.html
EOF
}

resource "aws_security_group" "alb" {
  name        = "ALB-SG"
  description = "ALB"
  vpc_id      = aws_vpc.homework.id

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

resource "aws_lb" "homework" {
    name = "lb-homework"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb.id]
    subnets = [aws_subnet.public.id, aws_subnet.private.id]
    ip_address_type = "ipv4"
}

resource "aws_lb_target_group" "homework" {
  name     = "lb-group-homework"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.homework.id
  #stickiness {
  #  type = "lb_cookie"
  #}
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/index.html"
    port = 80
  }
}

resource "aws_lb_listener" "lb-listener-http" {
  load_balancer_arn = aws_lb.homework.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.homework.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "public_http" {
  target_group_arn = aws_lb_target_group.homework.arn
  target_id        = aws_instance.app_server.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "private_http" {
  target_group_arn = aws_lb_target_group.homework.arn
  target_id        = aws_instance.private_server.id
  port             = 80
}


output "load_balancer" {
 value       = aws_lb.homework.dns_name
 description = "Load Balancer Endpoint"
}


