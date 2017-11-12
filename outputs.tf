output "public_ip" {
  description = "IP address associated to EC2 eth0"
  value = "${aws_instance.mpaggi.public_ip}"
}

output "id" {
  description = "EC2 instance ID"
  value       = "${aws_instance.mpaggi.id}"
}

output "public_dns" {
  description = "public DNS names assigned to the EC2-VPC"
  value       = "${aws_instance.mpaggi.public_dns}"
}

output "elastic_ip" {
  description = "Public IP address (elastic)"
 value = "${aws_eip.mpaggi_eip.public_ip}"
}
