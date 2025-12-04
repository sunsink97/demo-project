resource "aws_vpc" "resilience_architecture_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.env}-${var.project_name}-vpc"
    }
  )
}


resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-${var.project_name}-internet-gateway"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each                = var.az_map
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.key == "az1" ? 0 : 1)
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-${var.project_name}-public-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each                = var.az_map
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.key == "az1" ? 2 : 3)
  availability_zone       = each.value
  map_public_ip_on_launch = false # Secure: private only

  tags = {
    Name = "${var.project_name}-private-${each.key}"
  }
}

resource "aws_eip" "nat_eip" {
  for_each = var.az_map
  domain   = "vpc"
  

  tags = {
    Name = "${var.project_name}-nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each      = var.az_map
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.project_name}-nat-${each.key}"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  for_each = var.az_map
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${each.key}"
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = var.az_map
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = var.az_map
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private_rt[each.key].id
}
