resource "aws_glue_catalog_database" "raw" {
  name = "logidata_raw"
}

resource "aws_glue_catalog_database" "curated" {
  name = "logidata_curated"
}

resource "aws_glue_classifier" "csv_header" {
  name = "${var.naming.resource_prefix}-csv-header"
  csv_classifier {
    delimiter       = ","
    quote_symbol    = "\""
    contains_header = "PRESENT"
  }
}

resource "aws_glue_crawler" "raw_local" {
  name          = "${var.naming.resource_prefix}-crawler-raw-local"
  role          = var.glue_role_arn
  database_name = aws_glue_catalog_database.raw.name
  classifiers   = [aws_glue_classifier.csv_header.name]
  table_prefix  = "raw_local_"

  s3_target { path = "s3://${var.raw_bucket_name}/raw/local/" }

  schema_change_policy { 
    update_behavior = "UPDATE_IN_DATABASE" 
    delete_behavior = "LOG" 
    }
  recrawl_policy {
     recrawl_behavior = "CRAWL_EVERYTHING"
      }
}

resource "aws_glue_crawler" "raw_kinesis" {
  name          = "${var.naming.resource_prefix}-crawler-raw-kinesis"
  role          = var.glue_role_arn
  database_name = aws_glue_catalog_database.raw.name
  table_prefix  = "raw_kinesis_"

  s3_target { path = "s3://${var.raw_bucket_name}/raw/kinesis/" }

  schema_change_policy {
     update_behavior = "UPDATE_IN_DATABASE" 
     delete_behavior = "LOG"
      }
  recrawl_policy {
     recrawl_behavior = "CRAWL_EVERYTHING"
      }
}

resource "aws_glue_crawler" "curated" {
  name          = "${var.naming.resource_prefix}-crawler-curated"
  role          = var.glue_role_arn
  database_name = aws_glue_catalog_database.curated.name
  table_prefix  = "curated_"

  s3_target { path = "s3://${var.curated_bucket_name}/curated/" }

  schema_change_policy { 
    update_behavior = "UPDATE_IN_DATABASE"
     delete_behavior = "LOG"
      }

  recrawl_policy { 
    recrawl_behavior = "CRAWL_EVERYTHING"
     }
}