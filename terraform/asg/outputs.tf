output "alb_url" {
  description = "Public HTTP URL for the demo application."
  value       = "http://${aws_lb.app.dns_name}"
}

output "autoscaling_group_name" {
  description = "ASG name for health and scaling demonstrations."
  value       = aws_autoscaling_group.app.name
}

output "target_group_arn" {
  description = "Target group ARN used to inspect instance health."
  value       = aws_lb_target_group.app.arn
}
