resource "aws_security_group" "qledger-KOHO" {
  name = "qledger-KOHO"

  vpc_id = aws_vpc.qledger-KOHO.id

  // STAGE ENV ONLY - do not use in production
  ingress {
    protocol = "tcp"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}