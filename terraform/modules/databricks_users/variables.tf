locals {
  all_emails = toset(flatten(values(var.group_members)))
  group_member_relations = flatten([
    for group, emails in var.group_members : [
      for email in emails : {
        group_key = group
        email     = email
      }
    ]
  ])
}

variable "environment" {
    description = "Ambiente de implantação (ex: dev, staging, prod)"
    type        = string
}

variable "email_admin" {
    description = "E-mail do usuário administrador do Databricks, para adiconá-lo ao grupo de admins do workspace"
    type        = string
}

variable "workspace_id" {
    description = "ID do workspace do Databricks para atribuição de permissões"
    type = string
}

variable "group_members" {
    description = "Mapeamento de grupos e seus respectivos membros (e-mails)"
    type = map(list(string))
}