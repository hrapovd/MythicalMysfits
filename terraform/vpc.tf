variable "vpc_cidr" {
  type = map(string)
  default = {
    "vpc" : "10.0.0.0/16"
    "public1" : "10.0.0.0/24"
    "public2" : "10.0.1.0/24"
    "private1" : "10.0.2.0/24"
    "private2" : "10.0.3.0/24"
  }
}

# VPC definition with subnets
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "net10" {
  cidr_block           = var.vpc_cidr.vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_subnet" "pub1" {
  cidr_block              = var.vpc_cidr.public1
  vpc_id                  = aws_vpc.net10.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.gw10]
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_subnet" "pub2" {
  cidr_block              = var.vpc_cidr.public2
  vpc_id                  = aws_vpc.net10.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.gw10]
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_subnet" "priv1" {
  cidr_block              = var.vpc_cidr.private1
  vpc_id                  = aws_vpc.net10.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_subnet" "priv2" {
  cidr_block              = var.vpc_cidr.private2
  vpc_id                  = aws_vpc.net10.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false
  tags = {
    Project = "MythicalMysfits"
  }
}

# Gateway definitions with routes
resource "aws_internet_gateway" "gw10" {
  vpc_id = aws_vpc.net10.id
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_eip" "eip1" {
  vpc = true
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_eip" "eip2" {
  vpc = true
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.pub1.id
  depends_on    = [aws_internet_gateway.gw10]
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.eip2.id
  subnet_id     = aws_subnet.pub2.id
  depends_on    = [aws_internet_gateway.gw10]
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.net10.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw10.id
  }
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_route_table" "priv_rt1" {
  vpc_id = aws_vpc.net10.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat1.id
  }
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_route_table" "priv_rt2" {
  vpc_id = aws_vpc.net10.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat2.id
  }
  tags = {
    Project = "MythicalMysfits"
  }
}

resource "aws_route_table_association" "pub_rt_association1" {
  route_table_id = aws_route_table.pub_rt.id
  subnet_id      = aws_subnet.pub1.id
}

resource "aws_route_table_association" "pub_rt_association2" {
  route_table_id = aws_route_table.pub_rt.id
  subnet_id      = aws_subnet.pub2.id
}

resource "aws_route_table_association" "priv_rt_association1" {
  route_table_id = aws_route_table.priv_rt1.id
  subnet_id      = aws_subnet.priv1.id
}

resource "aws_route_table_association" "priv_rt_association2" {
  route_table_id = aws_route_table.priv_rt2.id
  subnet_id      = aws_subnet.priv2.id
}

# Endpoint to DynamoDB
resource "aws_vpc_endpoint" "dyndb_ep" {
  service_name = join("", ["com.amazonaws.", var.region, ".dynamodb"])
  vpc_id       = aws_vpc.net10.id
  route_table_ids = [
    aws_route_table.priv_rt1.id,
    aws_route_table.priv_rt2.id,
  ]
  tags = {
    Project = "MythicalMysfits"
  }
  policy = <<POLICY
{
  "Id": "DynamoDB_Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Principal": "*",
      "Resource": "*"
    }
  ]
}
POLICY
}