variable "naming" {
  type = object({
    resource_prefix = string
    tags            = map(string)
  })
}
variable "raw_bucket_name" { type = string }
variable "curated_bucket_name" { type = string }
variable "glue_role_arn" { type = string }