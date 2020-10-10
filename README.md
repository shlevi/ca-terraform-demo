# Terraform CA Demo
Demonstrate deployment and test of web app in AWS using Terraform modules

# Dependencies
This module depends on [hashicorp/http](https://registry.terraform.io/providers/hashicorp/http/latest) provider

# Hot to execute
Execute the following commands to run this module:
```
terraform init
```
```
terraform apply -var aws_profile="<your aws profile>" -auto-approve
```