#===================network======================================================================

resource "aws_internet_gateway" "igw_main" {
  vpc_id = aws_vpc.vpc_main.id
  tags = {
    Name = "${var.prefix}-gateway"
  }
}

data "aws_availability_zones" "aviable_zones" {
  state                   = "available"
}

resource "aws_subnet" "subnets" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.aviable_zones.names[count.index]
  map_public_ip_on_launch = "true"
}

resource "aws_db_subnet_group" "sub_db_sg_rds" {
  name       = "${var.prefix}-rds-subnet-db-sg"
  subnet_ids = [aws_subnet.subnets.0.id, aws_subnet.subnets.1.id]
  tags = {
    name = "${var.prefix}-rds-db-subnet-group"
  }
}

resource "aws_vpc" "vpc_main" {
  tags = {
    Name = "${var.prefix}-aws-vpc-main"
  }
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_route_table" "vpc_route" {
  vpc_id = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_main.id
  }
}

resource "aws_route_table_association" "vpc_route_assoc" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.vpc_route.id
}
