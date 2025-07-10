# Odoo Tools

Bộ công cụ tự động cài đặt, backup, khôi phục và quản lý Odoo 16 trên Linux server hoặc máy ảo Proxmox.

---

## 🧰 Nội dung

| Script | Mục đích |
|--------|----------|
| `install_odoo16.sh` | Cài đặt Odoo 16 từ đầu, tạo systemd |
| `uninstall_odoo16.sh` | Gỡ bỏ Odoo hoàn toàn |
| `backup_and_update.sh` | Sao lưu DB, filestore và cập nhật addon |
| `restore_odoo16.sh` | Khôi phục Odoo từ file `.tar.gz` backup |
| `setup_cron_backup.sh` | Thiết lập cron job để backup hàng ngày |
| `.env` | Biến cấu hình dùng chung cho các script |

---

## 🚀 Cách dùng

### 1. Tải các script về

```bash
git clone https://github.com/quannqttg/odoo-tools.git
cd odoo-tools
chmod +x *.sh
