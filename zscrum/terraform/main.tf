# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

module "networking" {
  source = "./modules/networking"

  app_name            = var.app_name
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "alb" {
  source = "./modules/alb"

  app_name          = var.app_name
  environment       = var.environment
  vpc_id           = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  container_port    = var.container_port
  depends_on = [module.networking]
} 

module "ecs" {
  source = "./modules/ecs"

  app_name               = var.app_name
  environment           = var.environment
  aws_region            = var.aws_region
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  container_port        = var.container_port
  container_cpu         = var.container_cpu
  container_memory      = var.container_memory
  desired_count         = var.desired_count
  database_url          = var.database_url
  clerk_publishable_key = var.clerk_publishable_key
  clerk_secret_key      = var.clerk_secret_key
  depends_on = [module.alb] 
}

module "cdn" {
  source = "./modules/cdn"

  app_name    = var.app_name
  environment = var.environment
  depends_on = [module.ecs]
}