variable "vpc" {
}
variable "ec2_type" {
}

variable "key_pair" {
}

variable "cidr_blocks" {
}

variable "subnet_id" {
}

variable "private" {
}

resource "aws_security_group" "allow_nat" {
  name        = "allow_nat"
  description = "Allow NAT traffic"
  vpc_id      = var.vpc.id
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
    cidr_blocks      = var.cidr_blocks
  }
  ingress {
    description      = "HTTPS from Private"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.cidr_blocks
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
  egress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Environment = "homework"
  }
}

resource "aws_network_interface" "nat_iface" {
  subnet_id = var.subnet_id
  source_dest_check = false
  security_groups = [aws_security_group.allow_nat.id]

  tags = {
    Name = "nat_instance_network_interface"
  }
}

resource "aws_instance" "nat_server" {
  ami           = "ami-0bc50b53fc59f31e0"
  instance_type = var.ec2_type
  key_name = var.key_pair
  network_interface {
    network_interface_id = aws_network_interface.nat_iface.id
    device_index = 0
  }
  tags = {
    Name = "NAT instance"
    Environment = "homework"
  }
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc.id

  route {
   cidr_block = "0.0.0.0/0"
   network_interface_id = aws_network_interface.nat_iface.id
  }

  tags = {
    Name = "Private"
    Environment = "homework"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private)

  subnet_id = var.private[count.index].id
  route_table_id = aws_route_table.private.id
}


output "bastion" {
    value = aws_instance.nat_server
}
