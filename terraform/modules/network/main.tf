#--VPC--#

resource "aws_vpc" "project-bedrock-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

#--SUBNETS--#

#--PUBLIC SUBNETS--#
resource "aws_subnet" "public-subnet-01" {
  vpc_id            = aws_vpc.project-bedrock-vpc.id
  cidr_block        = var.public_subnet_01_cidr
  availability_zone = var.availability_zone_1
  tags = {
    Name                                        = "public-subnet-01"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_subnet" "public-subnet-02" {
  vpc_id            = aws_vpc.project-bedrock-vpc.id
  cidr_block        = var.public_subnet_02_cidr
  availability_zone = var.availability_zone_2
  tags = {
    Name                                        = "public-subnet-02"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private-subnet-01" {
  vpc_id            = aws_vpc.project-bedrock-vpc.id
  cidr_block        = var.private_subnet_01_cidr
  availability_zone = var.availability_zone_1
  tags = {
    Name                                        = "private-subnet-01"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private-subnet-02" {
  vpc_id            = aws_vpc.project-bedrock-vpc.id
  cidr_block        = var.private_subnet_02_cidr
  availability_zone = var.availability_zone_2
  tags = {
    Name                                        = "private-subnet-02"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

#--INTERNET GATEWAY--#
resource "aws_internet_gateway" "project-bedrock-igw" {
  vpc_id = aws_vpc.project-bedrock-vpc.id
  tags = {
    Name = "project-bedrock-igw"
  }
}

#--NAT GATEWAY--#
resource "aws_eip" "project-bedrock-nat-eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "project-bedrock-nat-gw" {
  subnet_id     = aws_subnet.public-subnet-01.id
  allocation_id = aws_eip.project-bedrock-nat-eip.id
  tags = {
    Name = "project-bedrock-nat-gw"
  }
}

#--ROUTE TABLES--#

#--PUBLIC ROUTE TABLE--#
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.project-bedrock-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project-bedrock-igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

#--PRIVATE ROUTE TABLE--#
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.project-bedrock-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.project-bedrock-nat-gw.id
  }
  tags = {
    Name = "private-route-table"
  }
}

#--ROUTE TABLE ASSOCIATIONS--#

#--PUBLIC ROUTE TABLE ASSOCIATIONS--#
resource "aws_route_table_association" "public-route-table-association-01" {
  subnet_id      = aws_subnet.public-subnet-01.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-route-table-association-02" {
  subnet_id      = aws_subnet.public-subnet-02.id
  route_table_id = aws_route_table.public-route-table.id
}

#--PRIVATE ROUTE TABLE ASSOCIATIONS--#
resource "aws_route_table_association" "private-route-table-association-01" {
  subnet_id      = aws_subnet.private-subnet-01.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_route_table_association" "private-route-table-association-02" {
  subnet_id      = aws_subnet.private-subnet-02.id
  route_table_id = aws_route_table.private-route-table.id
}
