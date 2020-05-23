# Resources will be created in AWS
provider "aws" {
  region = var.aws_region
}

# Create a new VPC for the resources to be created
resource "aws_vpc" "lab_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Internet Gateway
resource "aws_internet_gateway" "lab_internet_gateway" {
  vpc_id = "${aws_vpc.lab_vpc.id}"
}

# Configure the AWS route for Internet access
resource "aws_route" "lab_internet_access" {
  route_table_id         = "${aws_vpc.lab_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.lab_internet_gateway.id}"
}

# Fetch list of availability zones in the selected region
data "aws_availability_zones" "available" {
  state = "available"
}

# Create fist availability zone for the web servers
resource "aws_subnet" "lab_web_primary" {
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id = aws_vpc.lab_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Create second availability zone for the web servers
resource "aws_subnet" "lab_web_secondary" {
  availability_zone = data.aws_availability_zones.available.names[1]
  vpc_id = aws_vpc.lab_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
}

# Create first availability zone for the RDS
resource "aws_subnet" "lab_db_primary" {
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id = aws_vpc.lab_vpc.id
  cidr_block = "10.0.3.0/24"
}

# Create second availability zone for the RDS
resource "aws_subnet" "lab_db_secondary" {
  availability_zone = data.aws_availability_zones.available.names[1]
  vpc_id = aws_vpc.lab_vpc.id
  cidr_block = "10.0.4.0/24"
}

# Load balancer security group that allows HTTP traffic
resource "aws_security_group" "lab_elb_sg" {
  description = "Allows HTTP traffic"
  vpc_id      = "${aws_vpc.lab_vpc.id}"

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
}

# Security group for the web servers
# SSH access can be limited to a given CIDR (for example, bastion host or proxy)
resource "aws_security_group" "lab_ec2_sg" {
  vpc_id      = "${aws_vpc.lab_vpc.id}"

  # SSH access from our cidrs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.source_cidrs
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our load balancer, we will add two web servers to it
resource "aws_elb" "lab_elb" {

  subnets         = ["${aws_subnet.lab_web_primary.id}","${aws_subnet.lab_web_secondary.id}"]
  security_groups = ["${aws_security_group.lab_elb_sg.id}"]
  instances       = ["${aws_instance.webserver_01.id}","${aws_instance.webserver_02.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

# RDS security group, allows access via port 3306
resource "aws_security_group" "lab_rds_sg" {
  description = "Allow traffic in port 3306 from web servers subnets"
  vpc_id      = "${aws_vpc.lab_vpc.id}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["${aws_subnet.lab_web_primary.cidr_block}", "${aws_subnet.lab_web_secondary.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lab_rds_sg"
  }
}


resource "aws_db_instance" "lab_rds" {
  depends_on             = [aws_security_group.lab_rds_sg]
  identifier             = "lab-rds"
  allocated_storage      = "5"
  engine                 = "mysql"
  engine_version         = "5.7.21"
  instance_class         = "db.t2.micro"
  name                   = var.rds_name
  username               = var.rds_username
  password               = var.rds_password
  vpc_security_group_ids = ["${aws_security_group.lab_rds_sg.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.lab_rds_subnetgroup.id}"
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "lab_rds_subnetgroup" {
  name        = "lab_rds_subnetgroup"
  subnet_ids  = ["${aws_subnet.lab_db_primary.id}", "${aws_subnet.lab_db_secondary.id}"]
}

resource "aws_key_pair" "lab_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "webserver_01" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    type = "ssh"
    user = "ubuntu"
    host = "${self.public_ip}"
    private_key = file(var.private_key_path)
    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.lab_auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.lab_ec2_sg.id}"]

  subnet_id = "${aws_subnet.lab_web_primary.id}"

  # We need this first provisioner, otherwise, we may execute the playbook
  # as soon as SSH is ready but the instance may not be ready yet
  # check https://github.com/scarolan/ansible-terraform and the talk https://www.hashicorp.com/resources/ansible-terraform-better-together/
  provisioner "remote-exec" {
    inline = ["echo 'Instance Ready Check'"]
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=\"False\" ansible-playbook -i '${self.public_ip},' ../configuration_management/deploy_application.yml --extra-vars 'rds_endpoint=\"${aws_db_instance.lab_rds.address}\" rds_user=\"${aws_db_instance.lab_rds.username}\" rds_password=\"${aws_db_instance.lab_rds.password}\" rds_database=\"${aws_db_instance.lab_rds.name}\"'"
  }
  # we need the DB to be ready before we provision the web servers
  depends_on = [aws_db_instance.lab_rds]
}

resource "aws_instance" "webserver_02" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    type = "ssh"
    user = "ubuntu"
    host = "${self.public_ip}"
    private_key = file(var.private_key_path)
    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.lab_auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.lab_ec2_sg.id}"]

  subnet_id = "${aws_subnet.lab_web_secondary.id}"

  provisioner "remote-exec" {
    inline = ["echo 'Instance Ready Check'"]
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=\"False\" ansible-playbook -i '${self.public_ip},' ../configuration_management/deploy_application.yml --extra-vars 'rds_endpoint=\"${aws_db_instance.lab_rds.address}\" rds_user=\"${aws_db_instance.lab_rds.username}\" rds_password=\"${aws_db_instance.lab_rds.password}\" rds_database=\"${aws_db_instance.lab_rds.name}\"'"
  }
  # we need the DB to be ready before we provision the web servers
  depends_on = [aws_db_instance.lab_rds]
}
