output "raw_database_name" { value = aws_glue_catalog_database.raw.name }
output "curated_database_name" { value = aws_glue_catalog_database.curated.name }
output "crawler_raw_local_name" { value = aws_glue_crawler.raw_local.name }
output "crawler_curated_name" { value = aws_glue_crawler.curated.name }
/* output "crawler_raw_kinesis_name" { value = aws_glue_crawler.raw_kinesis.name } */
