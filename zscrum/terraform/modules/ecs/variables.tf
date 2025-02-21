variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB security group ID"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 3000
}

variable "container_cpu" {
  description = "Container CPU units"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Container memory"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of containers"
  type        = number
  default     = 1
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "database_url" {
  description = "Database URL"
  type        = string
  sensitive   = true
}

variable "clerk_publishable_key" {
  description = "Clerk publishable key"
  type        = string
}

variable "clerk_secret_key" {
  description = "Clerk secret key"
  type        = string
  sensitive   = true
}

variable "clerk_sign_in_url" {
  description = "Clerk sign in URL"
  type        = string
  default     = "/sign-in"
}

variable "clerk_sign_up_url" {
  description = "Clerk sign up URL"
  type        = string
  default     = "/sign-up"
}

variable "clerk_after_sign_in_url" {
  description = "Clerk after sign in URL"
  type        = string
  default     = "/onboarding"
}

variable "clerk_after_sign_up_url" {
  description = "Clerk after sign up URL"
  type        = string
  default     = "/onboarding"
}