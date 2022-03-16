output "alb_dns_name" {
  description = "Public IP of the ALB"
  value = aws_lb.alb.dns_name
}