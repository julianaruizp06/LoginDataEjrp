output "resource_prefix" { value = module.naming.resource_prefix }

output "raw_bucket" { value = module.s3.raw_bucket_name }
output "curated_bucket" { value = module.s3.curated_bucket_name }
output "athena_results_bucket" { value = module.s3.athena_results_bucket_name }

output "kinesis_pedidos_stream" { value = module.kinesis.pedidos_stream_name }
output "kinesis_sensores_stream" { value = module.kinesis.sensores_stream_name }

output "firehose_pedidos" { value = module.firehose.pedidos_firehose_name }
output "firehose_sensores" { value = module.firehose.sensores_firehose_name }

output "athena_workgroup" { value = module.athena.workgroup_name }

output "glue_raw_db" { value = module.glue.raw_database_name }
output "glue_curated_db" { value = module.glue.curated_database_name }
output "glue_crawler_raw_local" { value = module.glue.crawler_raw_local_name }
output "glue_crawler_raw_kinesis" { value = module.glue.crawler_raw_kinesis_name }
output "glue_crawler_curated" { value = module.glue.crawler_curated_name }