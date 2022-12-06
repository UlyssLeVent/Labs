variable "vpc" {
}
variable "ami_id" {
}
variable "ec2_type" {
}
variable "key_pair" {
}
variable subnet_id {
}
variable setup_file {
}

resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Allow SSH"
  vpc_id      = var.vpc.id
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


resource "aws_instance" "backend" {
  ami           = var.ami_id
  instance_type = var.ec2_type
  key_name = var.key_pair
  associate_public_ip_address  = false
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  tags = {
      Name = "Backend"
      Environment = "homework"
  }
  user_data = filebase64(var.setup_file)
}

