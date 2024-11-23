resource "aws_backup_vault" "production-daily-bkp" {
  name        = "production-daily-bkp"
}

resource "aws_backup_plan" "production-daily-bkp" {
  name = "production-daily-bkp"

  rule {
    rule_name         = "production-daily-bkp"
    target_vault_name = aws_backup_vault.production-daily-bkp.name
    schedule          = "cron(0 12 * * ? *)"
  }

  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "enabled"
    }
    resource_type = "EC2"
  }
}