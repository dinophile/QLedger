// Useful for instances on your private subnets to access resources 
// for updates etc

// If you want a purely private subnet then you don't need to set this
// at all!!

// you'll need a static IP address using EIP elastic ip 
resource "aws_eip" "qledger_koho_nat" {
  vpc = true

  // sets the dependency on your igw since EIP may need it BEFORE 
  // it can associate
  depends_on = aws_internet_gateway.qledger_koho_igw.id
}

resource "aws_nat_gateway" "qledger_koho_ngw" {
  allocation_id = aws_eip.qledger_koho_nat.id
  subnet_id = aws_subnet.qledger_koho_public.allocation_id

  tags = {
    Name = "qledger_koho_nat_gateway"
  }
}

resource "aws_route_table" "qledger_koho_private" {
  vpc_id = aws_vpc.qledger_koho.id
  route = {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.qledger_koho_ngw.id
  }

  tags = {
    Name + "qledger_koho_private"
  }
}

resource "aws_route_table_associations" "qledger_koho_private" {
  subnet_id = aws_subnet.qledger_koho_private.id
  route_table_id = aws_route_table.qledger_koho_private.id
}