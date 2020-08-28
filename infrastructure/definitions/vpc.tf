data "aws_availability_zones" "available" {}

resource "aws_resource" "qledger-KOHO" {
  cidr_block = "10.0.0.0/16"

  enabled_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  count = var.az_count
  cidr_block = cidrsubnet(aws_vpc.qledger-KOHO.cidr_block, 8, count.index)
  vpc_id = aws_vpc.qledger-KOHO.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_internet_gateway" "qledger-KOHO-igw" {
  vpc_id = aws_vpc.qleder-KOHO.id
}