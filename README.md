# DevOps Lab

The project provides a set of configuration files that coupled with [Packer](https://www.packer.io/), [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/) provisions a simple web application in [AWS](https://aws.amazon.com/) to meet the following requirements:

1. Create a custom AMI based on a Linux distro
2. Deploy the AMI to enable a web server; the server will be behind a load balancer
3. The web server will not accept requests directly; instead, it will serve the requests through the load balancer only
4. Handle persistent data in RDS

### Implementation

Here is a diagram of the infrastructure that will be provisioned in AWS in order to enable the web application:  

![Simple Web Application diagram](https://github.com/jose-aguilera-lizano/alittlebitofeverything/blob/master/devops_lab_v1.png)

The web application itself has been taken from this [AWS Tutorial](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/TUT_WebAppWithRDS.html).

To go from zero to a fully functional web application, a two-steps approach is followed. Each step is complemented with basic configuration management. 

#### Step 1: OS image creation
In this step Packer is used to build a custom AMI backed by EBS volumes for use in EC2; the most recent [Ubuntu 18.04](https://releases.ubuntu.com/18.04.4/) AMI from Canonical is used as the source/base. Via Packer provisioners two Ansible playbooks are executed: the fist applies security updates while the second takes care of installing Apache and PHP. As a result, we get an AMI ID.   

#### Step 2: Application provisioning
In this step Terraform is used to provision new instances of all the services required to host and make the application work, from the VPC to the database; the EC2 instances we create to play the role of web servers are launched from the AMI created in the first step above. Once the infrastructure is ready, the web application is deployed via Ansible. As a result we get the DNS of the load balancer. 

### Built with
* [Packer](https://www.packer.io/) - Used to automate the creation of a custom AMI
* [Terraform](https://www.terraform.io/) - IaC (Infrastructure as Code) tool used to provision and manage the AWS infrastructure/services
* [Ansible](https://www.ansible.com/) - The automation engine used for configuration management and application deployment
