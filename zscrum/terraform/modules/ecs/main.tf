resource "aws_ecr_repository" "main" {
  name                 = "${var.app_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # Allows deletion of the repository with terraform destroy

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}"
    Environment = var.environment
  }
}
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.app_name}-ecs-cluster-${var.environment}"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.environment}"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.container_cpu
  memory                  = var.container_memory
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.app_name}-container"
      image = "${aws_ecr_repository.main.repository_url}:latest"
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY"
          value = var.clerk_publishable_key
        },
        {
          name  = "NEXT_PUBLIC_CLERK_SIGN_IN_URL"
          value = var.clerk_sign_in_url
        },
        {
          name  = "NEXT_PUBLIC_CLERK_SIGN_UP_URL"
          value = var.clerk_sign_up_url
        },
        {
          name  = "NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL"
          value = var.clerk_after_sign_in_url
        },
        {
          name  = "NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL"
          value = var.clerk_after_sign_up_url
        }
      ]
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_ssm_parameter.database_url.arn
        },
        {
          name      = "CLERK_SECRET_KEY"
          valueFrom = aws_ssm_parameter.clerk_secret_key.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.app_name}-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-service-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE" 

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.app_name}-container"
    container_port   = var.container_port
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-${var.environment}-ecs-tasks-sg"
  description = "Allow inbound traffic from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.app_name}-${var.environment}"
  retention_in_days = 30
}

# SSM Parameters
resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.app_name}/${var.environment}/DATABASE_URL"
  type  = "SecureString"
  value = var.database_url
}

resource "aws_ssm_parameter" "clerk_secret_key" {
  name  = "/${var.app_name}/${var.environment}/CLERK_SECRET_KEY"
  type  = "SecureString"
  value = var.clerk_secret_key
}