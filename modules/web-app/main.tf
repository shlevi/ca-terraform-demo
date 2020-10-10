terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region = "eu-central-1"
  profile = "ca-demo"
}

resource "aws_internet_gateway" "main" {
  vpc_id = var.vpc_id
}

resource "aws_route" "internet_access" {
  route_table_id         = var.route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_subnet" "main" {
  cidr_block = var.cidr_block
  vpc_id = var.vpc_id
  map_public_ip_on_launch = true
}

data "http" "my_public_ip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "elb" {
  name        = "ca-demo-elb-sg"
  description = "Used in the terraform"
  vpc_id      = var.vpc_id

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
  vpc_id      = var.vpc_id

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
  instances       = [aws_instance.web_instance.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_instance" "web_instance" {

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "ami-00a205cb8e06c3c4e"

  # The name of our SSH keypair we created above.
  key_name = "ca-demo"

  user_data = file("${path.module}/userdata")

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.web.id]

  subnet_id = aws_subnet.main.id

  connection {
    type = "ssh"
    user = "ec2-user"
    host = self.public_ip
    private_key = file("C:/Users/slevi/.ssh/ca-demo.pem")
  }

//  provisioner "remote-exec" {
//    inline = [
//      "sudo yum -y update",
//      "sudo amazon-linux-extras install -y nginx1",
//      "sudo service nginx start"
//    ]
//  }

//  provisioner "file" {
//    source      = "${path.module}/site.html"
//    destination = "/usr/share/nginx/html/site.html"
//  }

  provisioner "local-exec" {
    command = "cmd /c \"C:/Program Files (x86)/Google/Chrome/Application/chrome.exe\" http://${self.public_ip}/site.html"
    interpreter = ["PowerShell", "-Command"]
  }

  tags = {
    Name = "ca-demo-terraform",
  }

}
