variable "naming" { type = object({ resource_prefix = string tags = map(string) }) }
variable "raw_bucket_arn"      { type = string }
variable "raw_bucket_name"     { type = string }
variable "pedidos_stream_arn"  { type = string }
variable "sensores_stream_arn" { type = string }
variable "firehose_role_arn"   { type = string }