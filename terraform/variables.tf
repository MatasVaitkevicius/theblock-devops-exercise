variable "docker_compose_url" {
  description = "Github URL of the Docker Compose binary."
}

variable "compose_file_url" {
  description = "Github URL of the Docker Compose YAML file."
}

variable "nginx_conf_url" {
  description = "Github URL of the nginx configuration file."
}

variable "region" {
  description = "AWS region where the resources will be provisioned."
}