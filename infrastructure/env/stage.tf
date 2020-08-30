terraform {
  backend "s3" {
    bucket = "qledger-inf-state"
    key    = "stage_inf.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  shared_credentials_file = "$HOME/.aws/credentials"
  profile = "default"
  region  = "us-east-1"
}

module "qledger_koho" {
  source                       = "../../definitions"
  task_definition_path = var.qledger_koho_task_definition_path
}
