terraform {
  required_providers {
    restapi = {
      source = "fmontezuma/restapi"
      version = "1.14.1"
    }
  }
}

provider "restapi" {
  uri                  = "http://${var.web_app_public_ip}:${var.web_app_port}"
  debug                = false
  write_returns_object = false
}

//data "restapi_object" "get_id_1" {
//  path          = "/companies"
//  search_key    = "id"
//  search_value  = "1"
//}
