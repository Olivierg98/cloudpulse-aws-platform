output "url" {
  value = "${var.certificate_arn == null ? "http" : "https"}://${aws_lb.this.dns_name}"
}
output "vpc_id" {
  value = aws_vpc.this.id
}
output "autoscaling_group" {
  value = aws_autoscaling_group.app.name
}
output "dashboard" {
  value = aws_cloudwatch_dashboard.this.dashboard_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "database_secret_arn" {
  value     = try(aws_secretsmanager_secret.database[0].arn, null)
  sensitive = true
}

output "alarm_topic_arn" {
  value = try(aws_sns_topic.alerts[0].arn, null)
}
