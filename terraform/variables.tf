variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Used to prefix all resource names"
  type        = string
  default     = "octa-byte-devops"
}

variable "environment" {
  description = "staging or prod"
  type        = string
  default     = "staging"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}
