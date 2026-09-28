resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  cidr_block = var.public_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Tier = "public"
  }
}
resource "aws_subnet" "app" {
  count = length(var.app_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  cidr_block = var.app_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-app-${count.index + 1}"
    Tier = "private-app"
  }
}
resource "aws_subnet" "db" {
  count = length(var.db_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  cidr_block = var.db_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-db-${count.index + 1}"
    Tier = "private-db"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public-rt"
    Tier = "public"
  }
}
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
resource "aws_route_table" "app_private_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-app-private-rt-a"
    Tier = "private-app"
    AZ   = var.availability_zones[0]
  }
}

resource "aws_route_table" "app_private_b" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-app-private-rt-b"
    Tier = "private-app"
    AZ   = var.availability_zones[1]
  }
}
resource "aws_route_table" "db_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-db-private-rt"
    Tier = "private-db"
  }
}
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "app_private_a" {
  subnet_id      = aws_subnet.app[0].id
  route_table_id = aws_route_table.app_private_a.id
}

resource "aws_route_table_association" "app_private_b" {
  subnet_id      = aws_subnet.app[1].id
  route_table_id = aws_route_table.app_private_b.id
}
resource "aws_route_table_association" "db_private" {
  count = length(var.db_subnet_cidrs)

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db_private.id
}
resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-a"
  }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-b"
  }
}
resource "aws_nat_gateway" "a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat-a"
  }

  depends_on = [aws_internet_gateway.main]
}
resource "aws_nat_gateway" "b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public[1].id

  tags = {
    Name = "${var.project_name}-nat-b"
  }

  depends_on = [aws_internet_gateway.main]
}
resource "aws_route" "app_private_a_internet" {
  route_table_id         = aws_route_table.app_private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.a.id
}
resource "aws_route" "app_private_b_internet" {
  route_table_id         = aws_route_table.app_private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.b.id
}
