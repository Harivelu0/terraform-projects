# Terraform MERN Stack Deployment: NoteZipper

This repository contains Terraform configurations for deploying the NoteZipper MERN stack application on AWS. The setup includes all necessary infrastructure components for running the application in a production environment.

## Original Application

This infrastructure setup is based on the NoteZipper application:
- Original Repository: [NoteZipper](https://github.com/piyush-eon/notezipper)
- Stack: MongoDB, Express.js, React.js, Node.js

## Prerequisites

Before deployment, ensure you have:
- AWS Account and configured AWS CLI
- Terraform installed (version >= 1.0.0)
- MongoDB Atlas account (for database)
- Node.js 16.x (for local testing)

## Repository Structure

```plaintext
.
├── main.tf           # Main Terraform configuration
├── variables.tf      # Variable declarations
├── outputs.tf        # Output definitions
├── userdata.sh       # EC2 instance setup script
└── README.md        # This file
```

## Infrastructure Components

- EC2 instance running Ubuntu 20.04
- Security groups for application access
- Environment configuration
- MongoDB Atlas connection

## Quick Start

1. Clone the repository:
```bash
git clone <your-repository-url>
cd notezipper-terraform
```

2. Create `terraform.tfvars`:
```hcl
region       = "us-east-1"
instance_type = "t2.micro"
mongodb_uri  = "your-mongodb-uri"
jwt_secret   = "your-jwt-secret"
```

3. Initialize and apply Terraform:
```bash
terraform init
terraform plan
terraform apply
```

## EC2 User Data Script

The user data script performs the following setup:
- System updates
- Node.js 16.x installation
- Application cloning and dependency installation
- Environment configuration
- Application startup

## Security Group Configuration

```hcl
resource "aws_security_group" "app" {
  name = "notezipper-sg"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Environment Variables

Required environment variables:
- `PORT`: Application port (default: 5000)
- `MONGO_URI`: MongoDB connection string
- `NODE_ENV`: Environment (production/development)
- `JWT_SECRET`: Secret for JWT authentication

## Accessing the Application

After successful deployment:
- Backend API: `http://<ec2-public-ip>:5000`
- Frontend (Development): `http://<ec2-public-ip>:3000`

## Troubleshooting

Common issues and solutions:

1. **Application Not Starting**
   - Check user-data logs: `cat /var/log/user-data.log`
   - Verify Node.js version: `node --version`
   - Check MongoDB connection

2. **Port Access Issues**
   - Verify security group rules
   - Check if application is running: `ps aux | grep node`

3. **MongoDB Connection**
   - Ensure MongoDB URI is correct
   - Verify IP whitelist includes EC2 IP

## Cleanup

To remove all created resources:
```bash
terraform destroy
```

## Monitoring

Application logs can be found at:
- User data script: `/var/log/user-data.log`
- Application logs: Check PM2 logs if using PM2


## Acknowledgments

- Original NoteZipper application by [Piyush Agarwal](https://github.com/piyush-eon)
- Terraform documentation and community
- AWS documentation and community
