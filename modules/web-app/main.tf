terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region = "eu-central-1"
  profile = var.aws_profile
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
  vpc_security_group_ids = [var.security_group_id]

  subnet_id = var.subnet_id

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
