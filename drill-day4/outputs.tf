output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "instance_id" {
  value = aws_instance.web.id
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.web.public_ip}"
}

output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}

output "ssh_sg_id" {
  value = aws_security_group.ssh.id
}

output "web_sg_id" {
  value = aws_security_group.web.id
}