terraform {
  backend "s3" {
    bucket "qledger-koho"
    key = "stage_inf.tfstate"
    region =  var.AWS_REGION
  }
}

provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  region     = var.AWS_REGION
  profile = "default"
}

module "qledger-KOHO"{
  source = "../../definitions"

  qledger_task_definition_path = "../../task-defintions/qledger.json.tpl"
}