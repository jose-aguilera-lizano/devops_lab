# DevOps Lab

The project provides a set of configuration files that coupled with [Packer](https://www.packer.io/), [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/) provisions a simple web application in [AWS](https://aws.amazon.com/) to meet the following requirements:

1. Create a custom AMI based on a Linux distro
2. Deploy the AMI to enable a web server; the server will be behind a load balancer
3. The web server will not accept requests directly; instead, it will serve the requests through the load balancer only
4. Handle persistent data in RDS
