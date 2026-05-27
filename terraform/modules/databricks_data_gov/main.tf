resource "databricks_storage_credential" "external_creds" {
  name = "aws-s3-credential-${var.environment}"
  aws_iam_role {
    role_arn = var.unity_catalog_role_arn
  }

  force_destroy = var.environment == "dev" ? true : false
}

resource "databricks_external_location" "raw" {
  name            = "s3_raw_${var.environment}"
  url             = "s3://${var.bucket_raw_id}/"
  credential_name = databricks_storage_credential.external_creds.name
  force_destroy   = var.environment == "dev" ? true : false
}

resource "databricks_external_location" "bronze" {
  name            = "s3_bronze_${var.environment}"
  url             = "s3://${var.bucket_bronze_id}/"
  credential_name = databricks_storage_credential.external_creds.name
  force_destroy   = var.environment == "dev" ? true : false
}

resource "databricks_external_location" "silver" {
  name            = "s3_silver_${var.environment}"
  url             = "s3://${var.bucket_silver_id}/"
  credential_name = databricks_storage_credential.external_creds.name
  force_destroy   = var.environment == "dev" ? true : false
}

resource "databricks_external_location" "gold" {
  name            = "s3_gold_${var.environment}"
  url             = "s3://${var.bucket_gold_id}/"
  credential_name = databricks_storage_credential.external_creds.name
  force_destroy   = var.environment == "dev" ? true : false
}

resource "databricks_catalog" "raw_catalog" {
  name          = "raw"
  storage_root  = "s3://${var.bucket_raw_id}/"
  comment       = "Camada Raw - Dados Originais"
  force_destroy = var.environment == "dev" ? true : false

  depends_on = [databricks_external_location.raw]
}

resource "databricks_schema" "raw_schema" {
  name          = "external"
  catalog_name  = databricks_catalog.raw_catalog.name
  comment       = "Esquema para dados originais da camada Raw"
  force_destroy = var.environment == "dev" ? true : false
}

resource "databricks_volume" "raw_volume" {
  name         = "raw_volume_${var.environment}"
  catalog_name = databricks_catalog.raw_catalog.name
  schema_name  = databricks_schema.raw_schema.name
  volume_type  = "EXTERNAL"

  storage_location = "s3://${var.bucket_raw_id}/landing_zone/"

  depends_on = [databricks_external_location.raw]
}

resource "databricks_catalog" "bronze_catalog" {
  name          = "bronze"
  storage_root  = "s3://${var.bucket_bronze_id}/"
  comment       = "Camada Bronze - Dados Brutos"
  force_destroy = var.environment == "dev" ? true : false

  depends_on = [databricks_external_location.bronze]
}

resource "databricks_schema" "bronze_schema" {
  name          = "dbo"
  catalog_name  = databricks_catalog.bronze_catalog.name
  comment       = "Esquema para dados brutos da camada Bronze"
  force_destroy = var.environment == "dev" ? true : false
}

resource "databricks_catalog" "silver_catalog" {
  name          = "silver"
  storage_root  = "s3://${var.bucket_silver_id}/"
  comment       = "Camada Silver - Dados Limpos"
  force_destroy = var.environment == "dev" ? true : false

  depends_on = [databricks_external_location.silver]
}

resource "databricks_schema" "silver_schema" {
  name          = "dbo"
  catalog_name  = databricks_catalog.silver_catalog.name
  comment       = "Esquema para dados limpos da camada Silver"
  force_destroy = var.environment == "dev" ? true : false
}

resource "databricks_catalog" "gold_catalog" {
  name          = "gold"
  storage_root  = "s3://${var.bucket_gold_id}/"
  comment       = "Camada Gold - Prontos para BI"
  force_destroy = var.environment == "dev" ? true : false

  depends_on = [databricks_external_location.gold]
}

resource "databricks_schema" "gold_schema" {
  name          = "dbo"
  catalog_name  = databricks_catalog.gold_catalog.name
  comment       = "Esquema para dados prontos para BI da camada Gold"
  force_destroy = var.environment == "dev" ? true : false
}

resource "databricks_grants" "admin_raw" {
  catalog = databricks_catalog.raw_catalog.name
  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_grants" "admin_bronze" {
  catalog = databricks_catalog.bronze_catalog.name
  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_grants" "admin_silver" {
  catalog = databricks_catalog.silver_catalog.name
  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = var.user_group_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }
}

resource "databricks_grants" "admin_gold" {
  catalog = databricks_catalog.gold_catalog.name
  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = var.user_group_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }
}

resource "databricks_grants" "external_raw" {
  external_location = databricks_external_location.raw.name
  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_grants" "external_bronze" {
  external_location = databricks_external_location.bronze.name
  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_grants" "external_silver" {
  external_location = databricks_external_location.silver.name
  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_grants" "external_gold" {
  external_location = databricks_external_location.gold.name
  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_cluster_policy" "user_policy" {
  name = "Politica-Restrita-Users-${var.environment}"
  definition = jsonencode({
    "node_type_id" : {
      "type" : "allowlist",
      "values" : [
        "m5.xlarge",
        "m5.2xlarge",
        "r5.xlarge"
      ],
      "default" : "m5.xlarge"
    },
    "num_workers" : {
      "type" : "fixed",
      "value" : 0
    },
    "autoscale.max_workers" : {
      "type" : "forbidden"
    },
    "autoscale.min_workers" : {
      "type" : "forbidden"
    },
    "autotermination_minutes" : {
      "type" : "fixed",
      "value" : 10
    },
    "aws_attributes.availability" : {
      "type" : "fixed",
      "value" : "SPOT"
    },
    "aws_attributes.spot_bid_price_percent" : {
      "type" : "fixed",
      "value" : 100
    }
  })
}

resource "databricks_permissions" "policy_user_grant" {
  cluster_policy_id = databricks_cluster_policy.user_policy.id
  access_control {
    group_name       = var.user_group_name
    permission_level = "CAN_USE"
  }
}

resource "databricks_sql_endpoint" "user_warehouse" {
  name             = "SQL-Warehouse-Users-${var.environment}"
  cluster_size     = "2X-Small"
  min_num_clusters = 1
  max_num_clusters = 1
  auto_stop_mins   = 20

  warehouse_type            = "PRO"
  enable_serverless_compute = true
}

resource "databricks_permissions" "warehouse_user_grant" {
  sql_endpoint_id = databricks_sql_endpoint.user_warehouse.id
  access_control {
    group_name       = var.user_group_name
    permission_level = "CAN_USE"
  }
}

# CONEXOES COM O BANCO DE DADOS
resource "databricks_connection" "postgres_federation" {
  name            = "postgres_connection"
  connection_type = "POSTGRESQL"

  options = {
    host     = element(split(":", var.db_instance_endpoint), 0)
    port     = "5432"
    user     = var.db_username
    password = var.db_password
  }

  properties = {
    purpose = "testing"
  }
}

resource "databricks_grants" "postgres_connection_access" {
  foreign_connection = databricks_connection.postgres_federation.name

  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_catalog" "postgres_catalog" {
  name            = "federation_postgres"
  connection_name = databricks_connection.postgres_federation.name
  comment         = "Catalogo espelhado do Postgres de testes via Lakehouse Federation"

  options = {
    database = var.db_name
  }

  force_destroy = var.environment == "dev" ? true : false
  depends_on    = [databricks_connection.postgres_federation]
}

resource "databricks_grants" "postgres_catalog_grants" {
  catalog = databricks_catalog.postgres_catalog.name

  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

# CONEXAO COM AWS GLUE CATALOG
resource "databricks_credential" "service_glue" {
  name = "aws-glue-credential-service-${var.environment}"
  aws_iam_role {
    role_arn = var.databricks_glue_role_arn
  }
  purpose = "SERVICE"
  comment = "Conta de servico AWS-GLUE"
}

resource "databricks_external_location" "glue_s3_data" {
  name            = "s3_glue_data_${var.environment}"
  url             = "s3://${var.bucket_glue_data_id}/"
  credential_name = databricks_storage_credential.external_creds.name
  force_destroy   = var.environment == "dev" ? true : false
}

resource "databricks_grants" "external_glue_s3" {
  external_location = databricks_external_location.glue_s3_data.name
  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_connection" "glue_federation" {
  name            = "aws_glue_connection"
  connection_type = "GLUE"

  options = {
    aws_region     = var.aws_region
    aws_account_id = var.aws_account_id
    credential     = databricks_credential.service_glue.name
  }

  comment = "Conexao federada com o AWS Glue Catalog utilizando Role isolada de leitura"
}

resource "databricks_grants" "glue_connection_access" {
  foreign_connection = databricks_connection.glue_federation.name

  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}

resource "databricks_catalog" "glue_catalog" {
  name            = "federation_glue"
  connection_name = databricks_connection.glue_federation.name
  comment         = "Catalogo estrangeiro mapeando tabelas Hive/Iceberg do AWS Glue"

  force_destroy = var.environment == "dev" ? true : false

  options = {
    authorized_paths = "s3://${var.lakehouse_bucket_name}"
  }

  depends_on = [
    databricks_connection.glue_federation,
    databricks_external_location.glue_s3_data
  ]
}

resource "databricks_grants" "glue_catalog_grants" {
  catalog = databricks_catalog.glue_catalog.name

  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }
}
