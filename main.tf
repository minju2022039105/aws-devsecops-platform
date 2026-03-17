# 1. VPC 모듈 호출
module "network" {
  source = "./vpc"
}

# 2. S3 & WAF 모듈 호출
module "security" {
  source = "./waf"
  # 여기서 VPC 정보 등을 전달할 수 있습니다.
}

# 3. IAM 모듈 호출
module "identity" {
  source = "./iam"
}