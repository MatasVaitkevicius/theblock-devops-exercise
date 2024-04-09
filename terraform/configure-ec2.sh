#!/bin/bash

DOCKER_COMPOSE_URL= "https://github.com/docker/compose/releases/download/v2.26.1/docker-compose-$(uname -s)-$(uname -m)"
COMPOSE_FILE_URL= "https://raw.githubusercontent.com/MatasVaitkevicius/theblock-devops-exercise/main/docker-compose.yaml"
NGINX_CONF_URL= "https://raw.githubusercontent.com/MatasVaitkevicius/theblock-devops-exercise/main/nginx.conf"

# Update and install necessary packages
sudo yum update -y
sudo yum install docker git -y

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add the default user to the Docker group
sudo groupadd docker
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "$DOCKER_COMPOSE_URL" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Download docker-compose.yaml and nginx.conf
sudo curl -L "$COMPOSE_FILE_URL" -o ./docker-compose.yaml
sudo curl -L "$NGINX_CONF_URL" -o ./docker-compose.yaml

# Get the public IP address of the EC2 instance
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

EC2_PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
# Replace the placeholder with the actual IP address
sed -i "s/{EC2_PUBLIC_IP}/$EC2_PUBLIC_IP/g" ./docker-compose.yaml

# Start Docker Compose
sudo docker-compose up -d
