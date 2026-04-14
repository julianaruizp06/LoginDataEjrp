resource "aws_kinesis_stream" "pedidos" {
  name             = "${var.naming.resource_prefix}-pedidos-stream"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
  tags             = var.naming.tags
}

resource "aws_kinesis_stream" "sensores" {
  name             = "${var.naming.resource_prefix}-sensores-stream"
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"
  tags             = var.naming.tags
}