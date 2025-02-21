resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

tags={
    Name="${var.app_name}-vpc-${var.environment}"
}

}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name="${var.app_name}-public-subnet-${count.index+1}-${var.environment}"
  }
}
resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name="${var.app_name}-private-subnet-${count.index+1}-${var.environment}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags={
    Name="${var.app_name}-igw-${var.environment}"
  }
}
resource "aws_eip" "nat" {
  count = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${var.app_name}-eip-${count.index + 1}-${var.environment}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.app_name}-nat-${count.index + 1}-${var.environment}"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block="0.0.0.0/0"
    gateway_id=aws_internet_gateway.main.id
  }
  tags={
    Name="${var.app_name}-RT-${var.environment}"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block="0.0.0.0/0"
    nat_gateway_id=aws_nat_gateway.main[count.index].id
    
  }
}
resource "aws_route_table_association" "private" {
    count = length(var.availability_zones)
    subnet_id=aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private[count.index].id
  
}
