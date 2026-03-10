output "security_group_id" {
  value = aws_security_group.web_sg.id
}

output "launch_template_id" {
  value = aws_launch_template.web_template.id
}
output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}