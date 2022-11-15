resource "aws_sns_topic" "homework" {
  name = "homework"
  tags = {
    Environment = "homework"
  }
}

output "arn" {
    value = aws_sns_topic.homework.arn
}
