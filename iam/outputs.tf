output "admin_access_key" {
  value = aws_iam_access_key.admin_key.id
}

output "admin_secret_key" {
  value = aws_iam_access_key.admin_key.secret
}
