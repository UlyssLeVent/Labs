variable topic {
}


resource "aws_sns_topic" "homework" {
  name = var.topic
  tags = {
    Environment = "homework"
  }
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


output "arn" {
    value = aws_sns_topic.homework.arn
}

output "policy" {
    value = aws_iam_policy.sns
}
