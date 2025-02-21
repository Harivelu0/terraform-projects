# Jira Clone Terraform Deployment

This repository contains Terraform configurations for deploying a Jira clone application on AWS.

## Prerequisites
- AWS CLI configured
- Terraform >= 1.0.0
- Docker
- Node.js >= 18

## Quick Start
1. Setup infrastructure:
   ```bash
   cd terraform
   terraform init
   terraform plan -var-file="environments/dev/terraform.tfvars"
   terraform apply -var-file="environments/dev/terraform.tfvars"