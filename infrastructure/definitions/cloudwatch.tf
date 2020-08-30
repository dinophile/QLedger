resource "aws_cloudwatch_log_group" "qledger_koho" {
  name = format("/%s/qledger_koho", var.env)

  // 3 days for a staging envrionment, prod will be business needs specific
  retention_in_days = 3
}
