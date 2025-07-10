#!/bin/bash

# Nạp cấu hình
source "$(dirname "$0")/.env"

# Kiểm tra thư mục backup
mkdir -p "$BACKUP_DIR"

# Cấu hình biến
DB_NAME="nguyenanpc"  # hoặc lấy từ ENV nếu bạn set sẵn
DATE=$(date +"%Y%m%d_%H%M%S")
TMP_DIR="/tmp/odoo_backup_$DB_NAME"
DUMP_FILE="${TMP_DIR}/dump.dump"
FILESTORE="$ODOO_HOME/.local/share/Odoo/filestore/$DB_NAME"
BACKUP_FILE="${BACKUP_DIR}/odoo_${DB_NAME}_${DATE}.tar.gz"

# Tạo thư mục tạm
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# Dump database (format binary)
echo "🗄 Đang backup DB..."
sudo -u $ODOO_USER pg_dump -Fc -f "$DUMP_FILE" "$DB_NAME"

# Copy filestore
echo "📁 Sao chép filestore..."
cp -r "$FILESTORE" "$TMP_DIR/filestore"

# Copy cấu hình
echo "⚙️ Sao chép cấu hình odoo.conf..."
cp /etc/odoo.conf "$TMP_DIR/odoo.conf"

# Tạo file tar.gz
echo "📦 Tạo file backup nén..."
tar -czf "$BACKUP_FILE" -C "$TMP_DIR" .

# Xoá thư mục tạm
rm -rf "$TMP_DIR"

echo "✅ Hoàn tất backup: $BACKUP_FILE"

# ======================= Cập nhật addons =======================
echo "🔄 Đang cập nhật các custom addons..."
cd "$ODOO_HOME/custom_addons"
for d in */; do
    echo "→ Pulling $d"
    cd "$d"
    git pull || echo "❌ Không thể pull $d"
    cd ..
done
echo "✅ Đã cập nhật addons xong!"
