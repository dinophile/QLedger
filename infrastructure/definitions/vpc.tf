data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "qledger_koho" {
  cidr_block = "10.0.0.0/16"

  // These default to true
  enable_dns_support  = true
  enable_dns_hostnames = true
  
  // if you change this you're saying you need 
  // a dedicated bare metal machine for your instance
  // that costs $2/hour for AWS!! Default value is 'default',
  // 'dedicated' or 'host' are the $$ pricey options!
  instance_tenancy = "default"

  tags {
    Name = "qledger_koho"
  }

}

resource "aws_subnet" "public" {
  count             = var.az_count
  // I'm not sure I can set up a private using cidrsubnet? I'm not sure how to alter the cidr
  // block I'm putting in? Hmmm will need to dig more...
  // this value should output "10.0.0.0/24"
  cidr_blocks        = [cidrsubnet(aws_vpc.qledger_koho.cidr_block, 8, count.index)]
  vpc_id            = aws_vpc.qledger_koho.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = "true"

  tags = {
    Name = "qledger_koho_public"
  }
}

resource "aws_subnet" "private" {
  count             = var.az_count
  // for now I'll hard code my private cidr block
  cidr_blocks        = ["10.0.1.0/24"]
  vpc_id            = aws_vpc.qledger_koho.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = "false"
  tags = {
    Name = "qledger_koho_private"
  }
}

resource "aws_internet_gateway" "qledger_koho_igw" {
  vpc_id = aws_vpc.qledger_koho.id

  tags = {
    Name = "qledger_koho"
  }
}

// this will make sure traffic that doesn't match your subnet addresses enters
// the vpc via the internet gateway
resource "aws_route_table" "qledger_koho_public" {
  vpc_id = aws_vps.qledger_koho.vpc_id
  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = "aws_internet_gateway.qledger_koho_igw.id"
  }

  tags = {
    Name = "qledger_koho_public"
  }
}


// if you have multiple public subnets you'll need to add a route table association for each one 
resource "aws_route_table_association" "qledger_koho_public" {
  subnet_id = "aws_subnet.qledger_koho_public.id"
  route_table_id = "aws_route_table.qledger_koho_public.id"
}