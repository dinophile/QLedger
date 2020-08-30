resource "aws_ecs_cluster" "qledger_koho" {
  name = "qledger_koho"
}

data "template_file" "qledger_koho" {
  template = file(var.qledger_koho_task_definition_path)

  vars = {
    account    = var.account
    region     = var.region
    tag        = var.tag
    log_region = var.qledger_koho_port
    host_port  = var.qledger_koho_port
    env        = var.env
  }
}

resource "aws_ecs_task_definition" "qledger_koho" {
  family                   = "qledger_koho"
  execution_role_arn       = var.ecs_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.qledger_koho_cpu
  memory                   = var.qledger_koho_memory
  container_definitions    = data.template_file.qledger_koho.rendered
}

resource "aws_ecs_service" "qledger_koho" {
  name = "qledger_koho"

  cluster         = aws_ecs_cluster.qledger_koho.id
  task_definition = aws_ecs_task_definition.qledger_koho.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.qledger_koho.id]
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.http.arn
    container_name   = "qledger_koho"
    container_port   = var.qledger_koho_port
  }

  depends_on = [aws_alb_listener.qledger_koho]
}
