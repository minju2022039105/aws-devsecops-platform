provider "aws" {
  region = "us-east-1"
}

# 1. 최신 Ubuntu 24.04 AMI를 자동으로 검색 (이게 핵심!)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (우분투 공식 계정)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

module "network" {
  source = "./vpc"
}

module "identity" {
  source = "./iam"
}

module "security" {
  source = "./waf"
}

# 2. 검색한 최신 ID를 사용하여 EC2 생성
resource "aws_instance" "security_node" {
  ami           = data.aws_ami.ubuntu.id # <--- 자동으로 찾아온 ID 사용
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name

  subnet_id              = module.network.public_subnet_id
  vpc_security_group_ids = [module.network.security_group_id]
  
  iam_instance_profile = "devsecops-ec2-profile"

  tags = {
    Name = "DevSecOps-Analysis-Node"
  }
}

# 루트 아웃풋
output "admin_access_key" {
  value = module.identity.admin_access_key
}

output "admin_secret_key" {
  value     = module.identity.admin_secret_key
  sensitive = true
}

# main.tf 맨 아래에 추가
output "instance_public_ip" {
  value = aws_instance.security_node.public_ip
}
# 1. 내 PC에서 쓸 RSA 키 생성
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. AWS에 공인키 등록
resource "aws_key_pair" "deployer" {
  key_name   = "devsecops-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

# 3. 로컬 PC에 개인키 파일(.pem) 저장
resource "local_file" "private_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "my-key.pem"
}
