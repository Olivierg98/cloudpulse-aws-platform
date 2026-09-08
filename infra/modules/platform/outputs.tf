output "url" {
  value = "http://${aws_lb.this.dns_name}"
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
