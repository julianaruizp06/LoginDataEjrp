module "naming" {
  source        = "../../modules/naming"
  project       = var.project
  prefix        = var.prefix
  group         = var.group
  environment   = var.environment
  bucket_suffix = var.bucket_suffix
}

module "s3" {
  source = "../../modules/s3"
  naming = {
    raw_bucket_name            = module.naming.raw_bucket_name
    curated_bucket_name        = module.naming.curated_bucket_name
    athena_results_bucket_name = module.naming.athena_results_bucket_name
    tags                       = module.naming.tags
  }
}

module "iam" {
  source = "../../modules/iam"
  naming = { resource_prefix = module.naming.resource_prefix, tags = module.naming.tags }

  raw_bucket_arn      = module.s3.raw_bucket_arn
  raw_bucket_name     = module.s3.raw_bucket_name
  curated_bucket_arn  = module.s3.curated_bucket_arn
  curated_bucket_name = module.s3.curated_bucket_name
}

module "kinesis" {
  source = "../../modules/kinesis"
  naming = { resource_prefix = module.naming.resource_prefix, tags = module.naming.tags }
}

module "firehose" {
  source = "../../modules/firehose"
  naming = { resource_prefix = module.naming.resource_prefix, tags = module.naming.tags }

  raw_bucket_arn       = module.s3.raw_bucket_arn
  raw_bucket_name      = module.s3.raw_bucket_name
  pedidos_stream_arn   = module.kinesis.pedidos_stream_arn
  sensores_stream_arn  = module.kinesis.sensores_stream_arn
  firehose_role_arn    = module.iam.firehose_role_arn
}

module "athena" {
  source = "../../modules/athena"
  naming = { resource_prefix = module.naming.resource_prefix, tags = module.naming.tags }
  athena_results_bucket_name = module.s3.athena_results_bucket_name
}

module "glue" {
  source = "../../modules/glue"
  naming = { resource_prefix = module.naming.resource_prefix, tags = module.naming.tags }

  raw_bucket_name     = module.s3.raw_bucket_name
  curated_bucket_name = module.s3.curated_bucket_name
  glue_role_arn       = module.iam.glue_role_arn
}