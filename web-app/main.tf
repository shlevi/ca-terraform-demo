terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_vpc" "main" {
  cidr_block = "10.22.0.0/24"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_subnet" "main" {
  cidr_block              = aws_vpc.main.cidr_block
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
}

data "http" "my_public_ip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "elb" {
  name        = "ca-demo-elb-sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_public_ip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ca-demo-elb-sg"
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "web" {
  name        = "ca-demo-web-sg"
  description = "Used in the terraform"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_public_ip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ca-demo-web-sg"
  }
}

resource "aws_elb" "web" {
  name = "ca-demo-web-elb"

  subnets         = [aws_subnet.main.id]
  security_groups = [aws_security_group.elb.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_instance" "web_app_instance" {

  instance_type           = "t2.micro"
  ami                     = "ami-00a205cb8e06c3c4e"
  key_name                = "ca-demo"
  user_data               = file("${path.module}/userdata")
  subnet_id               = aws_subnet.main.id
  vpc_security_group_ids  = [aws_security_group.web.id, aws_security_group.elb.id]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = self.public_ip
    private_key = file("C:/Users/slevi/.ssh/ca-demo.pem")
  }

  provisioner "local-exec" {
    command     = "cmd /c \"C:/Program Files (x86)/Google/Chrome/Application/chrome.exe\" http://${self.public_ip}/site.html"
    interpreter = ["PowerShell", "-Command"]
  }

  tags = {
    Name = "ca-demo-terraform",
  }

}

output "web_instance_url" {
  value = "http://${aws_instance.web_app_instance.public_ip}/site.html"
}
