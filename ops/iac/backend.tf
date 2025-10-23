terraform {
  backend "s3" {
    bucket = "bardhi-ecom-terraform-state-dev"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}
