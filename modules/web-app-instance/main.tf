resource "tfe_ssh_key" "test" {
  name         = "ca-demo-pk"
  organization = "CADemo"
  key          = "ca-demo-pk"
}

resource "aws_instance" "web_app_instance" {

  instance_type           = "t2.micro"
  ami                     = "ami-00a205cb8e06c3c4e"
  key_name                = "ca-demo"
  user_data               = file("${path.module}/userdata")
  subnet_id               = var.subnet_id
  vpc_security_group_ids  = [var.security_group_id]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = self.public_ip
    private_key = tfe_ssh_key.test.id
  }

//  provisioner "local-exec" {
//    command     = "cmd /c \"C:/Program Files (x86)/Google/Chrome/Application/chrome.exe\" http://${self.public_ip}/site.html"
//    interpreter = ["PowerShell", "-Command"]
//  }

  tags = {
    Name = "ca-demo-terraform",
  }

}
