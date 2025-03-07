variable "aws_region" {
  description = "AWS_REGION"
  type = string
  default = "us-east-1"
}
variable "ami_id" {
  description = "ami value of ec2"
  type = string
}
variable "key_pair_name" {
  description = "name of the pem file"
  type = string
}
variable "mongodb_uri" {
  description = "MongoDB URI for the application"
  type        = string
  default = "${mongodb_uri}"
}

variable "jwt_secret" {
  description = "JWT secret for the application"
  type        = string
}