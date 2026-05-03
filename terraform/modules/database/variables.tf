variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for RDS"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to place the security group in"
}