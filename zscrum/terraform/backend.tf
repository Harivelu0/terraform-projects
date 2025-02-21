# terraform {
#   backend "s3" {
#     bucket         = "twh-terraform-state-bucket"
#     key            = "zscrum/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }