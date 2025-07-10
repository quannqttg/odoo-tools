#!/bin/bash

ODOO_USER=odoo
ODOO_HOME=/opt/odoo16
ODOO_SERVICE=odoo
ODOO_DB=odoo  # nếu có cơ sở dữ liệu tên khác, cần chỉnh lại

echo "🔧 Đang gỡ bỏ Odoo..."

# 1. Stop và disable service
sudo systemctl stop $ODOO_SERVICE
sudo systemctl disable $ODOO_SERVICE
sudo rm -f /etc/systemd/system/$ODOO_SERVICE.service
sudo systemctl daemon-reload

# 2. Xóa file cấu hình
sudo rm -f /etc/odoo.conf
sudo rm -f /var/log/odoo.log

# 3. Xóa thư mục Odoo
sudo rm -rf $ODOO_HOME

# 4. Xóa user và group
sudo userdel -r $ODOO_USER 2>/dev/null || echo "👤 Không tìm thấy user $ODOO_USER"
sudo groupdel $ODOO_USER 2>/dev/null || true

# 5. Xóa database nếu muốn
echo "⚠️ Bạn có muốn xóa toàn bộ database do user $ODOO_USER tạo không? (y/n)"
read -r confirm
if [[ $confirm == [yY] ]]; then
  sudo -u postgres dropdb --if-exists $ODOO_DB
  sudo -u postgres dropuser --if-exists $ODOO_USER
  echo "✅ Đã xóa database và user PostgreSQL."
fi

echo "✅ Odoo đã được gỡ bỏ hoàn toàn."
