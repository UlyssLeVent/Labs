resource "aws_dynamodb_table" "table" {
  name     = "edu-lohika-training-aws-dynamodb"
  read_capacity = 5
  write_capacity = 1
  hash_key = "UserName"
  attribute {
      name = "UserName"
      type = "S"
  }
  tags = {
    Name        = "homework"
    Environment = "homework"
  }
}


resource "aws_iam_policy" "dynamo" {
  name = "DDBPolicy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DDPolicy",
            "Effect": "Allow",
            "Action": "dynamodb:*",
            "Resource": "*"
        }
    ]
  })
}


output "policy" {
    value = aws_iam_policy.dynamo
}
