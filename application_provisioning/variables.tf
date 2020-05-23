variable "public_key_path" {
  description = "path to the public key"
}
variable "private_key_path" {
  description = "path to the private key"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}

variable "aws_amis" {
  default = {
    us-west-1 = "your AMI goes here"
    us-west-2 = "your AMI goes here"
  }
}

variable "source_cidrs" {
    default = [""]
}

variable "rds_name" {
  description = "rds_name"
}

variable "rds_username" {
  description = "rds_username"
}

variable "rds_password" {
  description = "rds_password"
}
