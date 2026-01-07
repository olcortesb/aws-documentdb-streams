resource "aws_docdb_subnet_group" "main" {
  name       = "${var.project_name}-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-subnet-group"
  })
}

resource "aws_docdb_cluster_parameter_group" "main" {
  family = "docdb5.0"
  name   = "${var.project_name}-cluster-params"

  parameter {
    name  = "change_stream_log_retention_duration"
    value = "10800"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cluster-params"
  })
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier              = "${var.project_name}-cluster"
  engine                          = "docdb"
  master_username                 = "docdbadmin"
  manage_master_user_password     = true
  backup_retention_period         = 1
  preferred_backup_window         = "07:00-09:00"
  skip_final_snapshot             = true
  storage_encrypted               = true
  db_subnet_group_name            = aws_docdb_subnet_group.main.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  vpc_security_group_ids          = [aws_security_group.docdb.id]
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cluster"
  })
}

resource "aws_docdb_cluster_instance" "main" {
  count              = 1
  identifier         = "${var.project_name}-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = "db.t3.medium"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-instance-${count.index}"
  })
}