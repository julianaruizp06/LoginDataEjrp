data "aws_caller_identity" "current" {}

resource "aws_iam_role" "glue" {
  name = "${var.naming.resource_prefix}-GlueServiceRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "glue.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.naming.tags
}

resource "aws_iam_role_policy" "glue_policy" {
  name = "${var.naming.resource_prefix}-GluePolicy"
  role = aws_iam_role.glue.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = [var.raw_bucket_arn, var.curated_bucket_arn] },
      { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], Resource = ["${var.raw_bucket_arn}/*", "${var.curated_bucket_arn}/*"] },
      { Effect = "Allow", Action = ["glue:*"], Resource = "*" }
    ]
  })
}

resource "aws_iam_role" "firehose" {
  name = "${var.naming.resource_prefix}-FirehoseDeliveryRole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "firehose.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.naming.tags
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "${var.naming.resource_prefix}-FirehosePolicy"
  role = aws_iam_role.firehose.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["kinesis:DescribeStream", "kinesis:GetShardIterator", "kinesis:GetRecords", "kinesis:ListShards"], Resource = "*" },
      { Effect = "Allow", Action = [
        "s3:AbortMultipartUpload", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads",
        "s3:GetObject", "s3:PutObject"
      ], Resource = [var.raw_bucket_arn, "${var.raw_bucket_arn}/*"] },
      { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = "*" }
    ]
  })
}

resource "aws_iam_role" "analyst" {
  name = "${var.naming.resource_prefix}-DataAnalystRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.naming.tags
}