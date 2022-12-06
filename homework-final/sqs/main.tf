variable "queue" {
}

resource "aws_sqs_queue" "homework" {
  name = var.queue
  tags = {
    Environment = "homework"
  }
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


output "url" {
    value = aws_sqs_queue.homework.url
}

output "policy" {
    value = aws_iam_policy.sqs
}
