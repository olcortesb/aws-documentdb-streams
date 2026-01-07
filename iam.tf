resource "aws_iam_role" "lambda_writer_role" {
  name = "${var.project_name}-lambda-writer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role" "lambda_stream_role" {
  name = "${var.project_name}-lambda-stream-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_writer_basic" {
  role       = aws_iam_role.lambda_writer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_stream_basic" {
  role       = aws_iam_role.lambda_stream_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "docdb_streams_policy" {
  name = "${var.project_name}-docdb-streams-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterParameters",
          "rds:DescribeDBSubnetGroups",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_stream_docdb" {
  role       = aws_iam_role.lambda_stream_role.name
  policy_arn = aws_iam_policy.docdb_streams_policy.arn
}