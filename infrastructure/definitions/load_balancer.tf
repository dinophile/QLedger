resource "aws_alb" "qledger-KOHO" {
  name = "qledger-KOHO"
  internal = false
  load_balancer_type = "application"
  subnet = aws_subnet.public.*.id 
  security_groups = [aws_security_group.qledger-KOHO.id]
  idle_timeout = 300
}

resource "aws_alb_target_group" "http" {
  name = "qledger-http-listener"
  port = var.qledger_port
  protocol = "HTTP"
  vpc_id = aws_vpc.qledger-KOHO.id
  target_type = "ip"

  health_check {
     healthy_threshold = "3"
     interval = "30"
     protocol = "HTTP"
     matcher = "200"
     timeout = "3"
     path = "/ping"
     unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "qledger-KOHO" {
  load_balancer_arn = aws_alb.qledger-KOHO.id
  port = var.qledger_port
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.http.id
    type = "forward"
  }
}

resource "aws_lb_listener_rule" "qledger" {
  listener_arn = aws_alb_listener.qledger.listener_arn

  priority = 1

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.http.arn
  }

  condition {
    path_pattern {
      values = ["/qledger*"]
    }
  }
}