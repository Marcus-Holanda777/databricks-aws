output "admin_group_id" {
  value       = databricks_group.this["ADMIN"].id
  description = "ID global do grupo de admin"
}

output "user_group_id" {
  value       = databricks_group.this["USER"].id
  description = "ID global do grupo de usuários comuns"
}

output "admin_group_name" {
  value       = databricks_group.this["ADMIN"].display_name
  description = "Nome do grupo de admin"
}

output "user_group_name" {
  value       = databricks_group.this["USER"].display_name
  description = "Nome do grupo de usuários comuns"
}