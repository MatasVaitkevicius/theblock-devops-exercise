provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket         = "the-block-crypto-state-bucket"
    key            = "terraform/state"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "the-block-crypto-table"
  }
}

data "http" "my_ip" {
  url = "https://api.ipify.org"
}

locals {
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  ingress {
    description = "TCP 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-01dad638e8f31ab9a"
  instance_type = "t3.micro"
  key_name      = "the-block-crypto"
  security_groups = [aws_security_group.allow_web.name]

  user_data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - docker
      - git
    runcmd:
      - systemctl start docker
      - systemctl enable docker
      - usermod -aG docker ec2-user
      - curl -L "${var.docker_compose_url}" -o /usr/local/bin/docker-compose
      - chmod +x /usr/local/bin/docker-compose
      - curl -L "${var.compose_file_url}" -o /home/ec2-user/docker-compose.yaml
      - curl -L "${var.nginx_conf_url}" -o /home/ec2-user/nginx.conf
      - |
        TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
        EC2_PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
        sed -i "s/{EC2_PUBLIC_IP}/$EC2_PUBLIC_IP/g" /home/ec2-user/docker-compose.yaml
      - cd /home/ec2-user/ && docker-compose up -d
    EOF

  tags = {
    Name = "TheBlockCrypto"
  }
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
  description = "The public IP address of the EC2 instance."
}
