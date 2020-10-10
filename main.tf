provider "aws" {
  region  = "eu-central-1"
  profile = var.aws_profile
}

resource "aws_vpc" "main" {
  cidr_block = "10.22.0.0/24"
}

module "deploy_demo_web_app" {
  source            = "./modules/web-app"
  vpc_id            = aws_vpc.main.id
  route_table_id    = aws_vpc.main.main_route_table_id
  cidr_block        = "10.22.0.0/24"
}

module "test" {
  source = "./modules/tests"

  web_app_public_ip = module.deploy_demo_web_app.web_instance_public_ip
}
