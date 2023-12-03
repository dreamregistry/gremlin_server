terraform {
  backend "s3" {}

  required_providers {
    docker = {
      source  = "registry.terraform.io/kreuzwerker/docker"
      version = "~>3.0"
    }

    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~>3.5"
    }
  }
}

provider "random" {}
provider "docker" {}

variable "port" {
  type    = number
  default = 8182
}

variable "network_mode" {
  type    = string
  default = "bridge"
}

variable "keep_locally" {
  default = false
}


resource "random_pet" "container_name" {
  length = 1
}

resource "docker_image" "gremlin_server" {
  name         = "tinkerpop/gremlin-server:latest"
  keep_locally = var.keep_locally
}

resource "docker_container" "gremlin_server" {
  image        = docker_image.gremlin_server.image_id
  name         = random_pet.container_name.id
  network_mode = var.network_mode

  command = ["./props/gremlin-server.yaml"]

  ports {
    internal = 8182
    external = var.port
  }

  volumes {
    host_path      = abspath("${path.module}/data")
    container_path = "/opt/gremlin-server/data"
  }

  volumes {
    host_path      = abspath("${path.module}/props")
    container_path = "/opt/gremlin-server/props"
  }
}



locals {
  port = var.network_mode == "host" ?  8182 : docker_container.gremlin_server.ports[0].external
}

output "GREMLIN_SERVER_URL" {
  sensitive = false
  value     = "ws://localhost:${local.port}/gremlin"
}
