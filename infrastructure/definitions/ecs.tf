resource "aws_ecs_cluster" "qledger" {
  name = "qledger"
}

data "template_file" "qledger" {
  template = file(var.qledger_task_definition_path)

  vars = {
    account = var.ACCOUNT
    region = var.AWS_REGION
    tag = var.tag
    log_region = var.qledger_port
    host_port = var.qledger_port
    env = var.env
  }
}

resource "aws_ecs_task_definiton" "qledger" {
  family = "qledger-KOHO"
  execution_role_arn = var.ecs_role_arn
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = var.qledger_cpu
  memory = var.qledger_memory
  container_definitions = data.template_file.qledger.rendered
}

resource "aws_ecs_service" "qledger" {
  name = "qledger"

  cluster = aws_ecs_cluster.qledger-KOHO.id
  aws_ecs_task_definition = aws_ecs_task_defintion.qledger.ecs_role_arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    sercurity_groups = [aws_security_group.qlegder-KOHO.id]
    subnets = aws_subnet.public.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.http.ecs_role_arn
    container_name = "qledger"
    port = var.qledger_port
  }

  depends_on = [ aws_alb_listener.qledger-KOHO ]
}