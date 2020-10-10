provider "aws" {
  region  = "eu-central-1"
  profile = "ca-demo"
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

output "web_app_url" {
  value = "http://${module.deploy_demo_web_app.web_instance_public_ip}:5000/companies"
}

module "test" {
  source = "./modules/tests"

  web_app_public_ip = module.deploy_demo_web_app.web_instance_public_ip
  web_app_port      = "5000"
}
