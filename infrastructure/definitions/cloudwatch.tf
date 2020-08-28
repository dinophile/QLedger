resource "aws_cloudwatch_log_group" "qledger_logs" {
  name = format("/%s/qledger", var.env)

  // 3 days for a staging envrionment, prod will be business specific
  retention_in_days = 3
}