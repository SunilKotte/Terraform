#watch for an error here!

output "public_dns" {
  description = "DNS name of the instance"
  value       = aws_instance.sg-instance.public_dns
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.sg-instance.public_ip
}