resource "aws_athena_workgroup" "wg" {
  name = "${var.naming.resource_prefix}-wg"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.athena_results_bucket_name}/athena-results/"
      encryption_configuration { encryption_option = "SSE_S3" }
    }
  }

  tags = var.naming.tags
}