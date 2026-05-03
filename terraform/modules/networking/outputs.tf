output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "app_server_id" {
  value       = data.aws_instance.app.id
  description = "Existing EC2 instance used as app server"
}

output "app_server_public_ip" {
  value       = data.aws_instance.app.public_ip
  description = "Public IP of app server"
}
