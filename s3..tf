# Create an AWS Backup vault in the backup region
resource "aws_backup_vault" "s3_backup_vault" {
  name        = "s3-backup-vault"
  kms_key_arn = aws_kms_key.backup_key.arn
}

# Create a KMS key for encrypting backups
resource "aws_kms_key" "backup_key" {
  description             = "KMS key for S3 backups"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# Create an AWS Backup plan
resource "aws_backup_plan" "s3_backup_plan" {
  name     = "s3-backup-plan"

  rule {
    rule_name         = "hourly-s3-backup"
    target_vault_name = aws_backup_vault.s3_backup_vault.name
    schedule          = "cron(0 0 * * ? *)"  # Daily backups at midnight UTC
    lifecycle {
      delete_after       = 14
    }
  }
}

# Create an AWS Backup selection for the destination bucket
resource "aws_backup_selection" "s3_backup_selection" {
  name         = "s3-backup-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.s3_backup_plan.id

  resources = [
    "arn:aws:s3:::testawsbackup10-11"
  ]
}

# Create an IAM role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name     = "s3-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary policies to the IAM role
resource "aws_iam_role_policy_attachment" "backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  role       = aws_iam_role.backup_role.name
}