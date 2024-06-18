#!/bin/bash
sudo yum update -y
sudo yum install -y nginx
sudo bash -c 'cat > /etc/nginx/conf.d/reverse-proxy.conf << "EOL"
server {
  listen 80;
  location / {
    proxy_pass http://${private_ip};
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
EOL'
sudo systemctl start nginx
sudo systemctl enable nginx
