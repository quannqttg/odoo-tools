#!/bin/bash

# Cấu hình chính
ODOO_USER=odoo
ODOO_HOME=/opt/odoo16
ODOO_PORT=8069
ODOO_SUPER_PWD=admin123
CUSTOM_ADDONS="$ODOO_HOME/custom_addons"

# Cài pkg system
sudo apt update && sudo apt upgrade -y
sudo apt install -y git python3-pip build-essential wget python3-dev libxml2-dev \
  libxslt1-dev zlib1g-dev libjpeg-dev libpq-dev libffi-dev python3-venv nodejs npm postgresql wkhtmltopdf

# Tạo user odoo
sudo useradd -m -d $ODOO_HOME -U -r -s /bin/bash $ODOO_USER || echo "User odoo đã tồn tại"
sudo mkdir -p $CUSTOM_ADDONS
sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME

# Tạo db user
sudo -u postgres createuser --createdb $ODOO_USER || echo "Postgres user đã tồn tại"

# Clone Odoo source
sudo -u $ODOO_USER -H git clone https://github.com/odoo/odoo --depth 1 --branch 16.0 $ODOO_HOME/odoo

# Tạo venv và cài dependencies
sudo -u $ODOO_USER -H python3 -m venv $ODOO_HOME/venv
sudo -u $ODOO_USER -H $ODOO_HOME/venv/bin/pip install wheel setuptools
sudo -u $ODOO_USER -H $ODOO_HOME/venv/bin/pip install -r $ODOO_HOME/odoo/requirements.txt

# Clone custom addons
sudo -u $ODOO_USER -H git clone https://github.com/OCA/account-financial-tools.git $CUSTOM_ADDONS/account-financial-tools
sudo -u $ODOO_USER -H git clone https://github.com/OCA/account-financial-reporting.git $CUSTOM_ADDONS/account-financial-reporting
sudo -u $ODOO_USER -H git clone https://github.com/CybroOdoo/base_accounting_kit.git $CUSTOM_ADDONS/base_accounting_kit
sudo -u $ODOO_USER -H git clone https://github.com/OCA/stock-logistics-barcode.git $CUSTOM_ADDONS/stock-logistics-barcode

# Tạo file cấu hình odoo.conf
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

sudo chown $ODOO_USER: /etc/odoo.conf
sudo chmod 640 /etc/odoo.conf

# Tạo systemd service
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

# Khởi động dịch vụ
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

echo "✅ Odoo 16 đã được cài! Truy cập: http://$(hostname -I | awk '{print $1}'):$ODOO_PORT"
echo "🔐 Admin password: $ODOO_SUPER_PWD"
