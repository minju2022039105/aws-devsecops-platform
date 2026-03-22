# EC2 Role & Policy
resource "aws_iam_role" "ec2_role" {
  name = "devsecops-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "devsecops-s3-access-policy"
  description = "Allow EC2 to read WAF logs from S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["s3:GetObject", "s3:ListBucket", "s3:PutObject"]
      Effect   = "Allow"
      Resource = [
        "arn:aws:s3:::aws-waf-logs-minju-0417-project",
        "arn:aws:s3:::aws-waf-logs-minju-0417-project/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "devsecops-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# IAM Admin User for Terraform
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
