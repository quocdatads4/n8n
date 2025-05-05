#!/bin/bash

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   echo "This script needs to be run with root privileges" 
   exit 1
fi

# Hàm kiểm tra domain
check_domain() {
    local domain=$1
    local server_ip=$(curl -s https://api.ipify.org)
    local domain_ip=$(dig +short $domain)

    if [ "$domain_ip" = "$server_ip" ]; then
        return 0  # Domain đã trỏ đúng
    else
        return 1  # Domain chưa trỏ đúng
    fi
}

# Nhận input domain từ người dùng
read -p "Enter your domain or subdomain: " DOMAIN

# Kiểm tra domain
if check_domain $DOMAIN; then
    echo "Domain $DOMAIN has been correctly pointed to this server. Continuing installation"
else
    echo "Domain $DOMAIN has not been pointed to this server."
    echo "Please update your DNS record to point $DOMAIN to IP $(curl -s https://api.ipify.org)"
    echo "After updating the DNS, run this script again"
    exit 1
fi

# Thư mục chính cho n8n
N8N_DIR="/home/n8n"

# Cài đặt Docker và Docker Compose
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose

# Tạo thư mục và file cấu hình cho n8n
mkdir -p $N8N_DIR
cat << EOF > $N8N_DIR/docker-compose.yml
version: "3"
services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=$DOMAIN
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://$DOMAIN
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
      - N8N_DIAGNOSTICS_ENABLED=false
    volumes:
      - $N8N_DIR:/home/node/.n8n
    dns:
      - 8.8.8.8
      - 1.1.1.1
EOF

# Đặt quyền cho thư mục
chown -R 1000:1000 $N8N_DIR
chmod -R 755 $N8N_DIR

# Khởi động container
cd $N8N_DIR
docker-compose up -d

echo ""
echo "╔═════════════════════════════════════════════════════════════╗"
echo "║                                                             ║"
echo "║  ✅ N8n đã được cài đặt thành công!                         ║"
echo "║                                                             ║"
echo "║  🌐 Truy cập n8n qua port: http://$(hostname -I | awk '{print $1}'):5678"
echo "║                                                             ║"
echo "║  📌 Tiếp theo, hãy cấu hình Reverse Proxy qua CyberPanel!   ║"
echo "║                                                             ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo ""
