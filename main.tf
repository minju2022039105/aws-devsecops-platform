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

# 4. 탄력적 IP (EIP) 할당: 인스턴스에 고정 IP 부여
resource "aws_eip" "analysis_node_eip" {
  instance = aws_instance.security_node.id # 위에서 정의한 security_node와 연결
  domain   = "vpc"

  tags = {
    Name = "DevSecOps-Fixed-IP"
  }
}

# 5. 최종 접속 IP 출력 (기존 instance_public_ip 출력문이 있다면 이걸로 대체하세요)
output "fixed_public_ip" {
  description = "접속에 사용할 고정 IP 주소입니다."
  value       = aws_eip.analysis_node_eip.public_ip
}

# 6. 방금 만든 alb 모듈을 불러오고, WAF와 연결
module "alb" {
  source         = "./alb"
  # module "vpc"가 아니라 위에서 만든 module "network"를 써야 합니다!
  vpc_id         = module.network.vpc_id 
  public_subnets = module.network.public_subnet_ids 
  
  # module "ec2" 모듈이 아니라 직접 만든 resource "aws_instance"의 ID를 씁니다!
  instance_id    = aws_instance.security_node.id 
}

# ⭐ WAF와 ALB를 실제 연결하는 코드
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = module.alb.alb_arn
  # module "security"라는 이름으로 불러오셨으니 이름을 맞춥니다!
  web_acl_arn  = module.security.web_acl_arn 
}