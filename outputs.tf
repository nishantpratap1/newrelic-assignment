output "instance_public_ip" {
  value = aws_instance.hello_world.public_ip
}

output "instance_id" {
  value = aws_instance.hello_world.id
}
