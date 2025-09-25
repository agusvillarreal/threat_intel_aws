variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile name (for SSO or named profiles)"
  type        = string
  default     = "default"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "opencti"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "opencti_admin_email" {
  description = "OpenCTI admin email"
  type        = string
  default     = "admin@opencti.io"
}

variable "opencti_admin_password" {
  description = "OpenCTI admin password"
  type        = string
  default     = "ChangeMePlease"
  sensitive   = true
}

variable "elastic_memory_size" {
  description = "Elasticsearch memory size"
  type        = string
  default     = "2g"
}

variable "instance_type" {
  description = "EC2 instance type for ECS tasks"
  type        = string
  default     = "t3.medium"
}

