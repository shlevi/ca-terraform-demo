terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
      version = "1.2.0"
    }
  }
}

provider "http" {
}

data "http" "test" {
  url = "http://${var.web_app_public_ip}/site.html"
}
