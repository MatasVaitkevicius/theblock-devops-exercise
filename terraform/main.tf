provider "aws" {
  region = var.region
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
      - usermod -aG docker $USER
      - curl -L "${var.docker_compose_url}" -o /usr/local/bin/docker-compose
      - chmod +x /usr/local/bin/docker-compose
      - curl -L "${var.compose_file_url}" -o .
      - curl -L "${var.nginx_conf_url}" -o .
      - docker-compose up -d
    EOF

  tags = {
    Name = "TheBlockCrypto"
  }
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
  description = "The public IP address of the EC2 instance."
}
