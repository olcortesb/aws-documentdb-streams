terraform {
  backend "s3" {
    key    = "aws-documentdb-streams/terraform.tfstate"
    bucket = "terraform-state-olcb"
    region = "eu-central-1"
  }
}