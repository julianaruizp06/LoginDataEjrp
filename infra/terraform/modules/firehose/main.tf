resource "aws_cloudwatch_log_group" "pedidos" {
  name              = "/aws/kinesisfirehose/${var.naming.resource_prefix}-pedidos-firehose"
  retention_in_days = 14
  tags              = var.naming.tags
}

resource "aws_cloudwatch_log_stream" "pedidos" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.pedidos.name
}

resource "aws_kinesis_firehose_delivery_stream" "pedidos" {
  name        = "${var.naming.resource_prefix}-pedidos-firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = var.pedidos_stream_arn
    role_arn           = var.firehose_role_arn
  }

  extended_s3_configuration {
    role_arn   = var.firehose_role_arn
    bucket_arn = var.raw_bucket_arn

    prefix              = "raw/kinesis/pedidos/ingest_date=!{timestamp:yyyy-MM-dd}/"
    error_output_prefix = "quarantine/firehose/pedidos/ingest_date=!{timestamp:yyyy-MM-dd}/!{firehose:error-output-type}/"

    buffering_interval = 60
    buffering_size     = 5
    compression_format = "UNCOMPRESSED"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.pedidos.name
      log_stream_name = aws_cloudwatch_log_stream.pedidos.name
    }

    processing_configuration {
      enabled = true
      processors {
        type = "AppendDelimiterToRecord"
        parameters {
          parameter_name  = "Delimiter"
          parameter_value = "\n"
        }
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "sensores" {
  name              = "/aws/kinesisfirehose/${var.naming.resource_prefix}-sensores-firehose"
  retention_in_days = 14
  tags              = var.naming.tags
}

resource "aws_cloudwatch_log_stream" "sensores" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.sensores.name
}

resource "aws_kinesis_firehose_delivery_stream" "sensores" {
  name        = "${var.naming.resource_prefix}-sensores-firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = var.sensores_stream_arn
    role_arn           = var.firehose_role_arn
  }

  extended_s3_configuration {
    role_arn   = var.firehose_role_arn
    bucket_arn = var.raw_bucket_arn

    prefix              = "raw/kinesis/sensores/ingest_date=!{timestamp:yyyy-MM-dd}/"
    error_output_prefix = "quarantine/firehose/sensores/ingest_date=!{timestamp:yyyy-MM-dd}/!{firehose:error-output-type}/"

    buffering_interval = 60
    buffering_size     = 5
    compression_format = "UNCOMPRESSED"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.sensores.name
      log_stream_name = aws_cloudwatch_log_stream.sensores.name
    }

    processing_configuration {
      enabled = true
      processors {
        type = "AppendDelimiterToRecord"
        parameters {
          parameter_name  = "Delimiter"
          parameter_value = "\n"
        }
      }
    }
  }
}