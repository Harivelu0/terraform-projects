output "public_ip" {
  description = "public ip of the ec2"
  value = aws_instance.notezipper_server.public_ip
}

output "public_dns" {
  description = "public ip of the ec2"
  value = aws_instance.notezipper_server.public_dns
}

