variable "naming" {
  type = object({
    resource_prefix = string
    tags            = map(string)
  })
}
variable "athena_results_bucket_name" {
  type = string
}