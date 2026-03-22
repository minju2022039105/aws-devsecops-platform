output "admin_access_key" {
  value = aws_iam_access_key.admin_key.id
  # Access Key ID는 공개되어도 비교적 안전하지만, 관례상 같이 둡니다.
}

output "admin_secret_key" {
  value     = aws_iam_access_key.admin_key.secret
  # ⭐️ 핵심: 이 옵션을 넣어야 터미널 화면에 비밀키가 안 뜹니다!
  sensitive = true 
}

# iam 모듈 내부에서 정의
output "ec2_profile_name" {
  description = "EC2가 사용할 IAM 인스턴스 프로필 이름입니다."
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_role_arn" {
  description = "The ARN of the IAM role for EC2"
  value       = aws_iam_role.ec2_role.arn
}