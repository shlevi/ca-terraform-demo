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

resource "aws_security_group" "elb" {
  name        = "ca-demo-elb-sg"
  description = "Used in the terraform"
  vpc_id      = var.vpc_id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
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

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
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

  provisioner "file" {
    source      = "${path.module}/app.py"
    destination = "~/app.py"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y python python-setuptools python-dev build-essential python-pip python-mysqldb git",
      "sudo pip install flask",
      "FLASK_APP=app.py flask run --host=0.0.0.0"
    ]
  }

  provisioner "local-exec" {
    command = "chrome.exe http://${self.public_ip}:5000/companies"
  }

  tags = {
    Name = "ca-demo-terraform",
  }

}

output "web_instance_public_ip" {
  value = aws_instance.web_instance.public_ip
}
