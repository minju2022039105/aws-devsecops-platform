resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "devsecops-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "devsecops-public-1a" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "devsecops-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "main_sg" {
  name   = "devsecops-main-sg"
  vpc_id = aws_vpc.main.id

  # SSH 접속용 (기존)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.143.64.148/32"]
  }

  # ⭐️ Grafana 접속용 (추가)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["49.143.64.148/32"] 
    description = "Allow Grafana access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 두 번째 퍼블릭 서브넷 (ALB를 위해 필요)
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"  # 첫 번째(10.0.1.0)와 겹치지 않게 수정
  availability_zone       = "us-east-1b"   # 첫 번째(1a)와 다른 1b로 설정
  map_public_ip_on_launch = true
  tags = { Name = "devsecops-public-1b" }
}

# 두 번째 서브넷도 인터넷이 되도록 라우트 테이블 연결
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}