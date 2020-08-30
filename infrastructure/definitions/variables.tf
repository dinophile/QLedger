 variable "qledger_koho_port" {
  default = "7001"
}

variable "env" {
  default = "stage"
}

variable "region" {
  default = "us-east-1"
}

variable "az_count" {
  default = 3
}

variable "ecs_role_arn" {
  default = "arn:aws:iam:349524346601:qledger-ecs-role"
}

variable "account" {
  default = "account number here but should be in .tfvars file"
}

variable "qledger_koho_cpu" {
  default = "256"
}

variable "qledger_koho_memory" {
  default = "512"
}

variable "tag" {
  default = "local"
}

variable "qledger_koho_task_definition_path" {
  default = "./task-definitions/qledger_koho.json.tpl"
}

