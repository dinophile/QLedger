resource "aws_alb" "qledger_koho" {
  name               = "qledger-koho"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public.*.id]
  security_groups    = [aws_security_group.qledger_koho.id]
  idle_timeout       = 300
}

// http for now, ssl later, would not expose in production
resource "aws_alb_target_group" "http" {
  name        = "qledger-koho-http-listener"
  port        = var.qledger_koho_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.qledger_koho.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/ping"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "qledger_koho" {
  load_balancer_arn = aws_alb.qledger_koho.id
  port              = var.qledger_koho_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.http.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "qledger_koho" {
  listener_arn = aws_alb_listener.qledger_koho.arn

  priority = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.http.arn
  }

  condition {
    path_pattern {
      values = ["/qledger*"]
    }
  }
}
