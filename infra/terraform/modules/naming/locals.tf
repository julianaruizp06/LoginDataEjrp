variable "project" {
  type        = string
  description = "Nombre del proyecto"
}

variable "group" {
  type        = string
  description = "Numero de grupo (ej: 01)"
}

variable "environment" {
  type        = string
  description = "Ambiente (dev/prod)"
}

variable "prefix" {
  type        = string
  description = "Prefijo base (ej: ejrp)"
}

locals {
  # ej: ejrp-g01-dev
  resource_prefix = "${var.prefix}-g${var.group}-${var.environment}"

  # Buckets sin ambiente (más estable / estándar del workshop)
  raw_bucket_name          = "${var.prefix}-g${var.group}-raw"
  curated_bucket_name      = "${var.prefix}-g${var.group}-curated"
  athena_results_bucket_name = "${var.prefix}-g${var.group}-athena-results"

  tags = {
    Project     = var.project
    Group       = var.group
    Environment = var.environment
    Prefix      = var.prefix
    ManagedBy   = "terraform"
  }
}