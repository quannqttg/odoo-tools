#!/bin/bash

# Nạp biến môi trường
source "$(dirname "$0")/.env"

# File tạm chứa cron job
TMP_CRON=$(mktemp)

# Ghi lại các cron cũ nếu có
crontab -l > "$TMP_CRON" 2>/dev/null

# Thêm dòng cron nếu chưa có
if ! grep -q "backup_and_update.sh" "$TMP_CRON"; then
    echo "0 3 * * * bash <(curl -sL https://raw.githubusercontent.com/quannqttg/odoo-tools/main/backup_and_update.sh) >> /var/log/odoo_backup.log 2>&1" >> "$TMP_CRON"
    crontab "$TMP_CRON"
    echo "✅ Đã thêm cron backup lúc 03:00 mỗi ngày."
else
    echo "ℹ️ Cron đã tồn tại, không cần thêm."
fi

# Xoá file tạm
rm "$TMP_CRON"
