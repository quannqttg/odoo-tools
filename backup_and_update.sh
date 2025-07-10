#!/bin/bash

source "$(dirname "$0")/.env"

# Cấu hình
BACKUP_DIR="/opt/odoo16/backups"
ODOO_HOME=/opt/odoo16
DB_NAME="nguyenanpc"
DB_USER="odoo"
FILESTORE="$ODOO_HOME/.local/share/Odoo/filestore/$DB_NAME"
DATE=$(date +"%Y%m%d_%H%M%S")
PG_DUMP="/usr/bin/pg_dump"

# Tạo thư mục backups nếu chưa có
mkdir -p "${BACKUP_DIR}"

# Dump DB
echo "🗄 Backup DB..."
sudo -u $DB_USER $PG_DUMP -U $DB_USER $DB_NAME > /tmp/${DB_NAME}_${DATE}.sql

# Tạo file backup
BACKUP_FILE="${BACKUP_DIR}/odoo_${DB_NAME}_${DATE}.tar.gz"
echo "📦 Tạo archive backup..."
tar -czf "$BACKUP_FILE" -C /tmp ${DB_NAME}_${DATE}.sql -C "$FILESTORE" . /etc/odoo.conf

# Xoá file dump tạm
rm /tmp/${DB_NAME}_${DATE}.sql
echo "✅ Backup hoàn tất: $BACKUP_FILE"

# Cập nhật addons bằng git pull
echo "🔄 Cập nhật addons..."
cd $ODOO_HOME/custom_addons
for d in */; do
    cd "$d"
    echo "→ Pulling $d"
    git pull || echo "Không thể pull $d"
    cd ..
done
echo "✅ Cập nhật addons xong!"
