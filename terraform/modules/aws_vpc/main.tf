resource "aws_vpc" "databricks_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-vpc",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.databricks_vpc.id

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-igw",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )

}

resource "aws_subnet" "public_az1" {
  vpc_id            = aws_vpc.databricks_vpc.id
  cidr_block        = var.public_subnet_cidr_1
  availability_zone = "${var.aws_region}a"

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-public-subnet-az1",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_subnet" "public_az2" {
  vpc_id            = aws_vpc.databricks_vpc.id
  cidr_block        = var.public_subnet_cidr_2
  availability_zone = "${var.aws_region}b"

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-public-subnet-az2",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.databricks_vpc.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = "${var.aws_region}a"

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-private-subnet-az1",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.databricks_vpc.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = "${var.aws_region}b"

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-private-subnet-az2",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_eip" "nat_eip" {
  count      = var.multi_az_nat ? 2 : 1
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]


  tags = merge(
    {
      Name        = "mvsh-databricks-${count.index}-${var.environment}-nat-eip",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_nat_gateway" "nat_gw" {
  count         = var.multi_az_nat ? 2 : 1
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = count.index == 0 ? aws_subnet.public_az1.id : aws_subnet.public_az2.id

  tags = merge(
    {
      Name        = "mvsh-databricks-${count.index}-${var.environment}-nat-gw",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.databricks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-public-rt",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  count  = var.multi_az_nat ? 2 : 1
  vpc_id = aws_vpc.databricks_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = merge(
    {
      Name        = "mvsh-databricks-${count.index}-${var.environment}-private-rt",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private_rt[0].id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = var.multi_az_nat ? aws_route_table.private_rt[1].id : aws_route_table.private_rt[0].id
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.databricks_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_rt[0].id,
    var.multi_az_nat ? aws_route_table.private_rt[1].id : aws_route_table.private_rt[0].id
  ]

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-s3-endpoint",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_security_group" "databricks_sg" {
  name        = "mvsh-databricks-sg-${var.environment}"
  vpc_id      = aws_vpc.databricks_vpc.id
  description = "Security Group interno para comunicacao entre clusters Spark"

  ingress {
    description = "Allow internal traffic between instances of the same security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "mvsh-databricks-sg-${var.environment}",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "mvsh-databricks-endpoint-sg-${var.environment}"
  vpc_id      = aws_vpc.databricks_vpc.id
  description = "Security Group exclusive for Interface VPC Endpoints"

  ingress {
    description = "Allow HTTPS from any internal VPC resource"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    description = "Block billing traffic or unnecessary egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "mvsh-databricks-endpoint-sg-${var.environment}",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_vpc_endpoint" "kinesis_endpoint" {
  vpc_id              = aws_vpc.databricks_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.kinesis-streams"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints_sg.id
  ]

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-kinesis-endpoint",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_vpc_endpoint" "sts_endpoint" {
  vpc_id              = aws_vpc.databricks_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints_sg.id
  ]

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-sts-endpoint",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

# Configuracao de redes para o RDS postgres
resource "aws_db_subnet_group" "postgres_subnets" {
  name        = "mvsh-databricks-${var.environment}-pg-subnet-group"
  description = "Sharing Databricks private subnets with Postgres"

  subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  tags = merge(
    {
      Name        = "mvsh-databricks-${var.environment}-pg-subnet-group",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}

resource "aws_security_group" "postgres_sg" {
  name        = "mvsh-postgres-sg-${var.environment}"
  vpc_id      = aws_vpc.databricks_vpc.id
  description = "Postgres Security Group - Allows strict access from Databricks"

  ingress {
    description     = "Allow inbound connection from Databricks Spark cluster"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.databricks_sg.id]
  }

  ingress {
    description = "Allow inbound connection from internal NLB for Databricks Serverless"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "mvsh-postgres-sg-${var.environment}",
      Environment = var.environment,
      Component   = "Network-Core",
    },
    var.tags,
  )
}