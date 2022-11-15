resource "aws_sqs_queue" "homework" {
  name = "sqs-homework"
  tags = {
    Environment = "homework"
  }
}

output "url" {
    value = aws_sqs_queue.homework.url
}
