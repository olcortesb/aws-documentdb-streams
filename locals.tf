locals {
  # Obtener credenciales del secreto
  docdb_secret = jsondecode(data.aws_secretsmanager_secret_version.docdb_password.secret_string)
  
  # Codificar usuario y contraseña para URL
  docdb_username_encoded = urlencode(aws_docdb_cluster.main.master_username)
  docdb_password_encoded = urlencode(local.docdb_secret["password"])
  
  # URI con credenciales codificadas
  docdb_uri = "mongodb://${local.docdb_username_encoded}:${local.docdb_password_encoded}@${aws_docdb_cluster.main.endpoint}:${aws_docdb_cluster.main.port}/?ssl=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}