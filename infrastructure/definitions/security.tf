resource "aws_security_group" "qledger_koho" {
  name = "qledger_koho"

  vpc_id = aws_vpc.qledger_koho.id

  // STAGE ENV ONLY - I would not use these in production!!
  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}
