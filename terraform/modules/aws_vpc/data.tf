locals {
  # IPs públicos de NAT que o Serverless usa para sair da rede Databricks em us-east-1
  databricks_serverless_nat_ips = [
    "3.221.144.128/28",
    "3.224.234.192/28",
    "3.226.79.160/28",
    "3.232.12.0/28",
    "34.195.122.128/28",
    "34.204.22.48/28",
    "34.228.14.0/28",
    "52.203.22.0/28",
    "52.204.232.160/28",
    "54.159.215.112/28"
  ]
}