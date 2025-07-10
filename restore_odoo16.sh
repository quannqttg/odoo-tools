#!/bin/bash

# Khôi phục dữ liệu Odoo từ file .tar.gz

source .env

BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Vui lòng cung cấp đường dẫn đến file backup .tar.gz"
    echo "➡️  Cách dùng: ./restore_odoo16.sh /path/to/backup.tar.gz"
    exit 1
fi

DB_NAME=$(basename "$BACKUP_FILE" | cut -d'_' -f1)

echo "🛠️ Đang khôi phục database: $DB_NAME từ $BACKUP_FILE"

# Tạm dừng Odoo
sudo systemctl stop odoo

# Giải nén
TMP_DIR="/tmp/odoo_restore_$DB_NAME"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
tar -xzf "$BACKUP_FILE" -C "$TMP_DIR"

# Khôi phục DB
sudo -u postgres dropdb --if-exists "$DB_NAME"
sudo -u postgres createdb "$DB_NAME" -O "$ODOO_USER"
sudo -u postgres pg_restore -d "$DB_NAME" "$TMP_DIR/dump.sql"

# Khôi phục filestore
FILERESTORE_DIR="$ODOO_HOME/.local/share/Odoo/filestore/$DB_NAME"
sudo rm -rf "$FILERESTORE_DIR"
sudo mkdir -p "$(dirname "$FILERESTORE_DIR")"
sudo cp -r "$TMP_DIR/filestore" "$FILERESTORE_DIR"
sudo chown -R $ODOO_USER:$ODOO_USER "$FILERESTORE_DIR"

# Khôi phục odoo.conf nếu có
if [ -f "$TMP_DIR/odoo.conf" ]; then
    sudo cp "$TMP_DIR/odoo.conf" /etc/odoo.conf
    sudo chown $ODOO_USER: /etc/odoo.conf
    sudo chmod 640 /etc/odoo.conf
fi

# Khởi động lại Odoo
sudo systemctl start odoo

echo "✅ Đã khôi phục database: $DB_NAME"
echo "🌐 Truy cập: http://$(hostname -I | awk '{print $1}'):$ODOO_PORT"
