#!/bin/bash

# ==========================================
# ✅ CÀI ĐẶT ODOO 16 TỰ ĐỘNG - CHUYÊN NGHIỆP
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

echo "📦 Bắt đầu cài đặt Odoo 16 vào $ODOO_HOME"

# ==========================================
# ✅ CÀI GÓI HỆ THỐNG
# ==========================================
sudo apt update && sudo apt upgrade -y
sudo apt install -y git python3-pip build-essential wget python3-dev libxml2-dev \
  libxslt1-dev zlib1g-dev libjpeg-dev libpq-dev libffi-dev python3-venv nodejs npm \
  postgresql wkhtmltopdf libsasl2-dev libldap2-dev libssl-dev

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
sudo -u "$ODOO_USER" -H git clone https://github.com/odoo/odoo --depth 1 --branch 16.0 "$ODOO_HOME/odoo"

# ==========================================
# ✅ TẠO VENV & CÀI PYTHON DEPENDENCIES
# ==========================================
echo "🐍 Tạo môi trường ảo Python..."
sudo -u "$ODOO_USER" -H python3 -m venv "$ODOO_HOME/venv"
sudo -u "$ODOO_USER" -H "$ODOO_HOME/venv/bin/pip" install --upgrade pip wheel setuptools
sudo -u "$ODOO_USER" -H "$ODOO_HOME/venv/bin/pip" install -r "$ODOO_HOME/odoo/requirements.txt"
sudo -u "$ODOO_USER" -H "$ODOO_HOME/venv/bin/pip" install python-ldap

# ==========================================
# ✅ CLONE CUSTOM ADDONS
# ==========================================
echo "📦 Đang clone các custom addons..."

sudo -u "$ODOO_USER" -H git clone https://github.com/OCA/account-financial-tools.git "$CUSTOM_ADDONS/account-financial-tools"
sudo -u "$ODOO_USER" -H git clone https://github.com/OCA/account-financial-reporting.git "$CUSTOM_ADDONS/account-financial-reporting"
sudo -u "$ODOO_USER" -H git clone https://github.com/OCA/stock-logistics-barcode.git "$CUSTOM_ADDONS/stock-logistics-barcode"

# Thử clone base_accounting_kit từ nguồn chính, nếu lỗi thì fallback sang fork
echo "📥 Clone base_accounting_kit..."
if sudo -u "$ODOO_USER" -H git clone https://github.com/CybroOdoo/base_accounting_kit.git "$CUSTOM_ADDONS/base_accounting_kit"; then
    echo "✅ Clone thành công từ CybroOdoo"
else
    echo "⚠️ Clone thất bại từ CybroOdoo. Đang thử từ fork cá nhân..."
    if sudo -u "$ODOO_USER" -H git clone https://github.com/quannqttg/base_accounting_kit.git "$CUSTOM_ADDONS/base_accounting_kit"; then
        echo "✅ Clone thành công từ fork cá nhân"
    else
        echo "❌ Không thể clone base_accounting_kit. Vui lòng kiểm tra quyền truy cập GitHub"
    fi
fi

# ==========================================
# ✅ TẠO FILE CẤU HÌNH odoo.conf
# ==========================================
echo "🛠️ Tạo file cấu hình /etc/odoo.conf"
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
echo "⚙️ Tạo dịch vụ systemd odoo.service"

sudo tee /etc/systemd/system/odoo.service > /dev/null <<EOF
[Unit]
Description=Odoo 16 Service
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
# ✅ KÍCH HOẠT VÀ KHỞI ĐỘNG DỊCH VỤ
# ==========================================
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

# ==========================================
# ✅ THÔNG BÁO HOÀN TẤT
# ==========================================
echo ""
echo "✅ Odoo 16 đã được cài đặt thành công!"
echo "🌐 Truy cập tại: http://$(hostname -I | awk '{print $1}'):$ODOO_PORT"
echo "🔐 Mật khẩu super admin: $ODOO_SUPER_PWD"
