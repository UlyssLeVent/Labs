resource "aws_vpc" "homework" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "LabVPC"
    Environment = "homework"
  }
}


resource "aws_internet_gateway" "homework" {
  vpc_id = aws_vpc.homework.id
  tags = {
    Name = "LabGW"
    Environment = "homework"
  }
}


resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.homework.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a"

  tags = {
    Name = "Public1"
    Environment = "homework"
  }
}


resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.homework.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2b"

  tags = {
    Name = "Public2"
    Environment = "homework"
  }
}


resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.homework.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "us-west-2c"

  tags = {
    Name = "Private1"
    Environment = "homework"
  }
}


resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.homework.id
  cidr_block = "10.0.12.0/24"
  availability_zone = "us-west-2d"

  tags = {
    Name = "Private2"
    Environment = "homework"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.homework.id

  route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.homework.id
  }

  tags = {
    Name = "Public"
    Environment = "homework"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "public2" {
  subnet_id = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}


output "vpc" {
    value = aws_vpc.homework
}

output "public" {
    value = [aws_subnet.public1, aws_subnet.public2]
}

output "private" {
    value = [aws_subnet.private1, aws_subnet.private2]
}

