#!/bin/bash

# Function to check if the script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script needs to be run with root privileges"
        exit 1
    fi
}

# Function to check if the domain is correctly pointed to this server
check_domain() {
    local domain=$1
    local server_ip=$(curl -s 
    
#!/bin/bash

# Function to check if the script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script needs to be run with root privileges"
        exit 1
    fi
}

# Function to check if the domain is correctly pointed to this server
check_domain() {
    local domain=$1
    local server_ip=$(curl -s https://api.ipify.org)
    local domain_ip=$(dig +short $domain)

    if [ "$domain_ip" == "$server_ip" ]; then
        return 0  # Domain is correctly pointed
    else
        return 1  # Domain is not correctly pointed
    fi
}

# Function to prepare n8n setup
setup_n8n() {
    local n8n_dir="/home/n8n"

    mkdir -p $n8n_dir

    # Create docker-compose.yml
    cat << EOF > $n8n_dir/docker-compose.yml
version: "3"
services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_HOST=${DOMAIN}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${DOMAIN}
      - GENERIC_TIMEZONE=Asia/Ho_Chi_Minh
    volumes:
      - $n8n_dir:/home/node/.n8n

  caddy:
    image: caddy:2
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - $n8n_dir/Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - n8n

volumes:
  caddy_data:
  caddy_config:
EOF

    # Create Caddyfile
    cat << EOF > $n8n_dir/Caddyfile
${DOMAIN} {
    reverse_proxy n8n:5678
}
EOF

    # Set permissions
    chown -R 1000:1000 $n8n_dir
    chmod -R 755 $n8n_dir

    # Start containers
    cd $n8n_dir
    docker-compose up -d

    echo "n8n has been installed and configured with SSL using Caddy. Access https://${DOMAIN} to use it."
    echo "Configuration files and data are stored in $n8n_dir"
}

# Main script execution
check_root

# Prompt user for domain input
read -p "Enter your domain or subdomain: " DOMAIN

# Check if the domain is pointed to this server
if check_domain $DOMAIN; then
    echo "Domain $DOMAIN has been correctly pointed to this server. Continuing installation."
else
    echo "Domain $DOMAIN has not been pointed to this server."
    echo "Please update your DNS record to point $DOMAIN to IP $(curl -s https://api.ipify.org)"
    echo "After updating the DNS, run this script again."
    exit 1


