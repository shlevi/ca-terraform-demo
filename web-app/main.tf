terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region  = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = "10.22.0.0/24"
}

module "demo_web_app_infra" {
  source            = "git::https://github.com/shlevi/web-app-infra.git?ref=webapp-infra"
  vpc_id            = aws_vpc.main.id
  cidr_block        = aws_vpc.main.cidr_block
  route_table_id    = aws_vpc.main.main_route_table_id
}

module "demo_web_app" {
  source            = "../modules/web-app-instance"
  security_group_id = module.demo_web_app_infra.security_group_id
  subnet_id         = module.demo_web_app_infra.subnet_id
}
