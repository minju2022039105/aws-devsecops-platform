# ==========================================
# 1. EC2 & Lambda Role (전체 통합 버전)
# ==========================================
resource "aws_iam_role" "ec2_role" {
  name = "devsecops-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { 
        Service = [
          "ec2.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      }
    }]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "devsecops-s3-access-policy"
  description = "Allow EC2 and Lambda to access S3, KMS, Athena, CloudWatch and Invoke Lambda"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # (1) S3 권한
      {
        Action   = ["s3:GetObject", "s3:ListBucket", "s3:PutObject","s3:GetBucketLocation","s3:GetEncryptionConfiguration"]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::aws-waf-logs-minju-0417-project",
          "arn:aws:s3:::aws-waf-logs-minju-0417-project/*"
        ]
      },
      # (2) KMS 권한
      {
        Action = ["kms:GenerateDataKey", "kms:Decrypt", "kms:DescribeKey"]
        Effect   = "Allow"
        Resource = "arn:aws:kms:us-east-1:095035153545:key/f05a310f-3c92-4b81-af3d-a51050e17b46"
      },
      # (3) Athena & CloudWatch 권한
      {
        Action = [
          "athena:*",
          "glue:*",
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # (4) ⭐️ 핵심: Analyzer가 Preventer를 깨울 수 있는 권한 추가!
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = "*" # 보안상 "arn:aws:lambda:us-east-1:095035153545:function:SecurityPreventer" 로 적어주면 더 좋아요!
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# ==========================================
# 2. IAM Admin User for Terraform
# ==========================================
resource "aws_iam_user" "devsecops_admin" {
  name = "devsecops-admin-user"
  path = "/system/"
}

resource "aws_iam_user_policy_attachment" "admin_attach" {
  user       = aws_iam_user.devsecops_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "admin_key" {
  user = aws_iam_user.devsecops_admin.name
}

# ==========================================
# 3. EC2 Instance Profile (에러 해결용 추가)
# ==========================================
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "devsecops-ec2-profile"
  role = aws_iam_role.ec2_role.name
}