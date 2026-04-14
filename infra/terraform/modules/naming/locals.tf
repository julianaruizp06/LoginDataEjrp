locals {
  resource_prefix = "${var.prefix}-g${var.group}-${var.environment}"
  suffix          = trimspace(var.bucket_suffix) != "" ? "-${var.bucket_suffix}" : ""

  raw_bucket_name            = "${var.prefix}-g${var.group}-raw${local.suffix}"
  curated_bucket_name        = "${var.prefix}-g${var.group}-curated${local.suffix}"
  athena_results_bucket_name = "${var.prefix}-g${var.group}-athena-results${local.suffix}"

  tags = {
    Project     = var.project
    Group       = var.group
    Environment = var.environment
    Prefix      = var.prefix
    ManagedBy   = "terraform"
  }
}