# Terraform CA Demo
Demonstrate deployment and test of web app in AWS using Terraform modules

# External Dependencies
This module depends on:
* Hashicorp's [hashicorp/http](https://registry.terraform.io/providers/hashicorp/http/latest) provider
* Remote github module [web-app-infra](https://github.com/shlevi/web-app-infra)

# Hot to execute
Execute the following commands to run this module:
```
terraform init
```
```
terraform apply -var aws_profile="<your aws profile>" -auto-approve
```