output "workspace_url" {
  description = "URL de acesso ao Workspace criado (usada para configurar os próximos providers)"
  value       = databricks_mws_workspaces.this.workspace_url
}

output "workspace_id" {
  description = "ID do Workspace criado"
  value       = databricks_mws_workspaces.this.workspace_id
}