resource "databricks_mws_network_connectivity_config" "serverless_ncc" {
  account_id = var.databricks_account_id
  name       = "mvsh-ncc-${var.environment}"
  region     = var.aws_region
}

resource "databricks_mws_ncc_binding" "serverless_ncc_binding" {
  network_connectivity_config_id = databricks_mws_network_connectivity_config.serverless_ncc.network_connectivity_config_id
  workspace_id                   = var.databricks_workspace_id
}

resource "databricks_mws_ncc_private_endpoint_rule" "postgres_serverless_rule" {
  network_connectivity_config_id = databricks_mws_network_connectivity_config.serverless_ncc.network_connectivity_config_id
  endpoint_service               = var.vpc_endpoint_service_name
  connection_state               = "PENDING"
}