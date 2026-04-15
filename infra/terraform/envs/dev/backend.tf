terraform {
  backend "s3" {
    bucket  = "logidata-tfstate-288742313330"
    key     = "logidata/dev/terraform.tfstate"
    region  = "us-east-2"
    profile = "logidata"
    encrypt = true
  }
}
