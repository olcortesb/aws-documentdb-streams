data "aws_secretsmanager_secret" "docdb_password" {
  name = aws_docdb_cluster.main.master_user_secret[0].secret_arn
}

data "aws_secretsmanager_secret_version" "docdb_password" {
  secret_id = data.aws_secretsmanager_secret.docdb_password.id
}