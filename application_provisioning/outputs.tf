output "address" {
  value = "${aws_elb.lab_elb.dns_name}"
}
