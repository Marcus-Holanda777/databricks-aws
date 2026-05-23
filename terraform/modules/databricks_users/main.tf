resource "databricks_group" "this" {
  for_each = var.group_members
  display_name = "GROUP_${upper(each.key)}_${upper(var.environment)}"
}

resource "databricks_user" "this" {
  for_each = local.all_emails
  user_name    = each.value
  display_name = split("@", each.value)[0]
}

resource "databricks_group_member" "this" {
  for_each = {
    for rel in local.group_member_relations : "${rel.group_key}-${rel.email}" => rel
  }

  group_id  = databricks_group.this[each.value.group_key].id
  member_id = databricks_user.this[each.value.email].id
}

resource "databricks_group_member" "add_admin_me" {
  group_id  = databricks_group.this["ADMIN"].id
  member_id = data.databricks_user.me.id
}

resource "databricks_mws_permission_assignment" "this" {
  for_each     = var.group_members
  workspace_id = var.workspace_id
  principal_id = databricks_group.this[each.key].id
  permissions  = [each.key]
}