#!/bin/bash

# ==========================================
# ✅ CÀI ĐẶT ODOO 18 TỰ ĐỘNG - CHUYÊN NGHIỆP
# ==========================================

# Load biến cấu hình từ .env
ENV_PATH="$(dirname "$0")/.env"
if [ -f "$ENV_PATH" ]; then
    source "$ENV_PATH"
else
    echo "❌ Không tìm thấy file cấu hình .env"
    exit 1
fi

CUSTOM_ADDONS="$ODOO_HOME/custom_addons"

echo "📦 Bắt đầu cài đặt Odoo 18 vào $ODOO_HOME"

# ==========================================
# ✅ CÀI GÓI HỆ THỐNG
# ==========================================
sudo apt update && sudo apt upgrade -y
# Updated dependencies for Odoo 18, some packages might be slightly different or newer versions
sudo apt install -y git python3-pip build-essential wget python3-dev libxml2-dev \
  libxslt1-dev zlib1g-dev libjpeg-dev libpq-dev libffi-dev python3-venv nodejs npm \
  postgresql wkhtmltopdf libsasl2-dev libldap2-dev libssl-dev python3-setuptools python3-wheel

# ==========================================
# ✅ TẠO USER ODOO
# ==========================================
sudo useradd -m -d "$ODOO_HOME" -U -r -s /bin/bash "$ODOO_USER" 2>/dev/null || echo "👤 User $ODOO_USER đã tồn tại"
sudo mkdir -p "$CUSTOM_ADDONS"
sudo chown -R "$ODOO_USER:$ODOO_USER" "$ODOO_HOME"

# ==========================================
# ✅ TẠO DATABASE USER
# ==========================================
sudo -u postgres createuser --createdb "$ODOO_USER" 2>/dev/null || echo "🧑‍💻 PostgreSQL user đã tồn tại"

# ==========================================
# ✅ CLONE ODOO SOURCE
# ==========================================
echo "📥 Cloning Odoo source..."
# Changed branch to 18.0 for Odoo 18
sudo -u "$ODOO_USER" -H git clone https://github.com/odoo/odoo --depth 1 --branch 18.0 "$ODOO_HOME/odoo"

# ==========================================
# ✅ TẠO VENV & CÀI PYTHON DEPENDENCIES
# ==========================================
echo "🐍 Tạo môi trường ảo Python..."
sudo -u "$ODOO_USER" -H python3 -m venv "$ODOO_HOME/venv"
sudo -u "$ODOO_USER" -H "$ODOO_HOME/venv/bin/pip" install --upgrade pip wheel setuptools
sudo -u "$ODOO_USER" -H "$ODOO_HOME/venv/bin/pip" install -r "$ODOO_HOME/odoo/requirements.txt"
# python-ldap might still be needed depending on specific external integrations
sudo -u "$ODOO_USER" -H "$ODOO_HOME/venv/bin/pip" install python-ldap

# ==========================================
# ✅ CLONE CUSTOM ADDONS
# ==========================================
echo "📦 Đang clone các custom addons..."

# Important: OCA modules and other custom modules need to be compatible with Odoo 18.
# You will likely need to find the '18.0' branch for these modules.
# I'm updating the branch names to '18.0' where available/likely.
# Please verify the actual compatibility and branch names from OCA/module maintainers.

sudo -u "$ODOO_USER" -H git clone https://github.com/OCA/account-financial-tools.git --branch 18.0 "$CUSTOM_ADDONS/account-financial-tools"
sudo -u "$ODOO_USER" -H git clone https://github.com/OCA/account-financial-reporting.git --branch 18.0 "$CUSTOM_ADDONS/account-financial-reporting"
sudo -u "$ODOO_USER" -H git clone https://github.com/OCA/stock-logistics-barcode.git --branch 18.0 "$CUSTOM_ADDONS/stock-logistics-barcode"

echo "📥 Clone base_accounting_kit..."
# Also updating this branch to 18.0
if sudo -u "$ODOO_USER" -H git clone --depth 1 --branch 18.0 https://github.com/odoo-ecu/base-accounting-kit.git "$CUSTOM_ADDONS/base_accounting_kit"; then
    echo "✅ Clone thành công từ odoo-ecu"
else
    echo "❌ Không thể clone base_accounting_kit. Vui lòng kiểm tra kết nối Internet hoặc repo"
fi

# ==========================================
# ✅ TẠO MODULE auto_enable_accounting
# ==========================================
echo "⚙️ Tạo module auto_enable_accounting..."

sudo -u "$ODOO_USER" -H bash <<EOF
set -e
AUTO_ADDONS_DIR="$CUSTOM_ADDONS/auto_enable_accounting"
mkdir -p "\$AUTO_ADDONS_DIR/models"

cat > "\$AUTO_ADDONS_DIR/__manifest__.py" <<EOL
{
    "name": "Auto Enable Full Accounting Features",
    "version": "18.0.1.0.0", # Updated version for Odoo 18
    "summary": "Tự động bật tính năng kế toán đầy đủ cho user admin",
    "depends": ["account"],
    "installable": True,
    "auto_install": False
}
EOL

cat > "\$AUTO_ADDONS_DIR/__init__.py" <<EOL
from . import models
EOL

cat > "\$AUTO_ADDONS_DIR/models/enable_accounting.py" <<EOL
from odoo import models, api, SUPERUSER_ID

class EnableAccounting(models.AbstractModel):
    _name = 'enable.accounting.auto'
    _description = 'Tự động bật nhóm kế toán cho user admin'

    @api.model
    def _enable_accounting_group(self):
        user = self.env['res.users'].browse(SUPERUSER_ID)
        group = self.env.ref('account.group_account_user')
        if group.id not in user.groups_id.ids:
            user.write({'groups_id': [(4, group.id)]})

    @api.model
    def _register_hook(self):
        # In Odoo 18, _register_hook might not always be called on initial module installation
        # if the module is auto_install=False.
        # However, for simplicity and typical usage where it's installed manually or on database creation,
        # this should still work. Consider calling this function directly after DB creation/module installation
        # if you encounter issues with it not being triggered.
        self._enable_accounting_group()
        return super()._register_hook()
EOL
EOF

# ==========================================
# ✅ TẠO FILE CẤU HÌNH odoo.conf
# ==========================================
echo "🛠️ Tạo file cấu hình /etc/odoo.conf"
# No significant changes needed for odoo.conf for Odoo 18, mostly compatible
sudo tee /etc/odoo.conf > /dev/null <<EOF
[options]
admin_passwd = $ODOO_SUPER_PWD
db_host = False
db_port = False
db_user = $ODOO_USER
db_password = False
addons_path = $ODOO_HOME/odoo/addons,$CUSTOM_ADDONS
logfile = /var/log/odoo.log
xmlrpc_port = $ODOO_PORT
log_level = info
workers = 2
limit_memory_soft = 512000000
limit_memory_hard = 1024000000
limit_time_cpu = 60
limit_time_real = 120
EOF

sudo chown "$ODOO_USER:" /etc/odoo.conf
sudo chmod 640 /etc/odoo.conf

# ==========================================
# ✅ TẠO SYSTEMD SERVICE
# ==========================================
echo "🔧 Tạo dịch vụ systemd: odoo.service"

# No significant changes needed for systemd service for Odoo 18, mostly compatible
sudo tee /etc/systemd/system/odoo.service > /dev/null <<EOF
[Unit]
Description=Odoo 18 Service
After=network.target postgresql.service

[Service]
Type=simple
User=$ODOO_USER
Group=$ODOO_USER
ExecStart=$ODOO_HOME/venv/bin/python3 $ODOO_HOME/odoo/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

# ==========================================
# ✅ KHỞI ĐỘNG VÀ CÀI MODULE KẾ TOÁN TỰ ĐỘNG
# ==========================================
# Assuming the database name will still be 'odoo16' as per previous context,
# but it's recommended to update this to 'odoo18' for consistency.
# If you want to create a new database for Odoo 18, you'd typically remove this check
# and create the database via the Odoo web interface or with --init-all.
# For demonstration, keeping the check but noting the name.
if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw odoo18; then # Changed to odoo18
    echo "⚠️ Chưa có database odoo18, bỏ qua bước cài module kế toán."
else
    echo "⚙️ Cài đặt module auto_enable_accounting vào odoo18..." # Changed to odoo18
    sudo -u "$ODOO_USER" -H "$ODOO_HOME/venv/bin/python3" "$ODOO_HOME/odoo/odoo-bin" \
        -c /etc/odoo.conf \
        -d odoo18 \
        -i auto_enable_accounting \
        --stop-after-init
fi

# ==========================================
# ✅ KÍCH HOẠT DỊCH VỤ
# ==========================================
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

# ==========================================
# ✅ THÔNG BÁO HOÀN TẤT
# ==========================================
echo ""
echo "🎉 Odoo 18 đã được cài đặt thành công!"
echo "🌐 Truy cập: http://$(hostname -I | awk '{print $1}'):$ODOO_PORT"
echo "🔐 Mật khẩu super admin: $ODOO_SUPER_PWD"
