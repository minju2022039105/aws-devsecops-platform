# 1. EC2가 사용할 신뢰 정책 (EC2 서비스가 이 역할을 가질 수 있게 허용)
resource "aws_iam_role" "ec2_role" {
  name = "devsecops-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. S3 읽기/쓰기 권한 정책 (WAF 로그 분석용)
resource "aws_iam_policy" "s3_access_policy" {
  name        = "devsecops-s3-access-policy"
  description = "Allow EC2 to read WAF logs from S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::aws-waf-logs-minju-source-2026",
          "arn:aws:s3:::aws-waf-logs-minju-source-2026/*"
        ]
      }
    ]
  })
}

# 3. 역할과 정책 연결
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# 4. EC2 인스턴스에 입힐 프로파일 (실제 EC2 생성 시 이걸 사용함)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "devsecops-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
