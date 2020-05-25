# DevOps Lab

The project provides a set of configuration files that coupled with [Packer](https://www.packer.io/), [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/) provisions a simple web application in [AWS](https://aws.amazon.com/) to meet the following requirements:

1. Create a custom AMI based on a Linux distro
2. Deploy the AMI to enable a web server; the server will be behind a load balancer
3. The web server will not accept requests directly; instead, it will serve the requests through the load balancer only
4. Handle persistent data in RDS

## Implementation

Here is a diagram of the infrastructure that will be provisioned in AWS in order to enable the web application:  

![Simple Web Application diagram](https://github.com/jose-aguilera-lizano/alittlebitofeverything/blob/master/devops_lab_v1.png)

The web application itself has been taken from this [AWS Tutorial](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/TUT_WebAppWithRDS.html).

To go from zero to a fully functional web application, a two-steps approach is followed. Each step is complemented with basic configuration management. 

### Step 1: OS image creation
In this step Packer is used to build a custom AMI backed by EBS volumes for use in EC2; the most recent [Ubuntu 18.04](https://releases.ubuntu.com/18.04.4/) AMI from Canonical is used as the source/base. Via Packer provisioners two Ansible playbooks are executed: the fist applies security updates while the second takes care of installing Apache and PHP. As a result, we get an AMI ID.   

### Step 2: Application provisioning
In this step Terraform is used to provision new instances of all the services required to host and make the application work, from the VPC to the database; the EC2 instances we create to play the role of web servers are launched from the AMI created in the first step above. Once the infrastructure is ready, the web application is deployed via Ansible. As a result we get the DNS of the load balancer. 

## Installation and usage

### Prerequisites
1. Access to an [AWS account](https://aws.amazon.com/account/); it includes up to 12 months of Free Tier access
2. At least one IAM user with programmatic access to interact with AWS. For Packer, a policy document with the minimun set of permissions for Packer to work is available [here](https://www.packer.io/docs/builders/amazon/)
3. A host where to execute the tools listed at [Built with](https://github.com/jose-aguilera-lizano/devops_lab#built-with). 
4. The tools binaries available in your systems's PATH

For this project I installed all the tools in a single Ubuntu 18.04 EC2 instance. For Packer and Terraform, I downloaded the Linux package, unzipped it and added the binary to the system's PATH. For Ansible, the following commands were executed:
```sh
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```
### Clone the repository
To get this project files locally, clone the repository:
```
git clone https://github.com/jose-aguilera-lizano/devops_lab.git
```
The command above will create a new directory called **devops_lab** in your current directory.

### Usage

#### Step 1: OS image creation
1. Access the directory **os_image_creation**; this directory is right under the directory **devops_lab**
2. Open the file **variables.json** and edit it; consider the following:
  - One must never commit and push unencrypted credentials to GitHub; the first two variables (**aws_access_key** and **aws_secret_key**) have placeholder values; set your IAM user credentials here
  - By default, us-west-2 is used for the **aws_region**; [here](https://www.cloudping.info/) you can check the latency from your browser to multiple AWS regions and adjust the value accordinly
  - By default, when Packer creates an EC2 instance from the source/base AMI it creates a temporary security group that allows SSH access to everyone out there. We can set the **source_cidrs** to limit what host or hosts will have access to the temporary EC2 instance. For example, you can set the value to your laptop's public IP address
  - With **ami_name** you define the name for the custom AMI that Packer will create; in the **ubuntu_web_server.json** file we append a timestamp to this AMI name is order to make it unique
3. Execute the Packer command to build the custom AMI: `packer build -var-file=variables.json ubuntu_web_server.json`; once the AMI is ready you will get the AMI ID as shown in the screenshot below. Please take note of the AMI ID as it is needed for the infrastructure provisioning.

![AMI ID](https://github.com/jose-aguilera-lizano/alittlebitofeverything/blob/master/devlops_ami.png)

#### Step 2: Application provisioning
1. Access the directory **application_provisioning**; this directory is right under the directory **devops_lab**

## Built with
* [Packer](https://www.packer.io/) - Used to automate the creation of a custom AMI
* [Terraform](https://www.terraform.io/) - IaC (Infrastructure as Code) tool used to provision and manage the AWS infrastructure/services
* [Ansible](https://www.ansible.com/) - The automation engine used for configuration management and application deployment
