variable "cidr_block" {
}


resource "aws_security_group" "postgres" {
  name        = "allow_postgres"
  description = "Allow Postgres inbound traffic"

  ingress {
    description      = "Postgres"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = [var.cidr_block]
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
  db_name= "EduLohikaTrainingAwsRds"
  engine = "postgres"
  engine_version = "13.7"
  instance_class = "db.t3.micro"
  username = "rootuser"
  password = "rootuser"
  publicly_accessible = false
  storage_encrypted   = false
  skip_final_snapshot = true
  max_allocated_storage = 0

  vpc_security_group_ids = [aws_security_group.postgres.id]
}

output "endpoint" {
    value = aws_db_instance.postgres.endpoint
}


