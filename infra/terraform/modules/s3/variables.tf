variable "naming" {
  type = object({
    raw_bucket_name            = string
    curated_bucket_name        = string
    athena_results_bucket_name = string
    tags                       = map(string)
  })
}