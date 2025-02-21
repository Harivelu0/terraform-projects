output "cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.main.repository_url
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "service_name" {
  value = aws_ecs_service.app.name
}