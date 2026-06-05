output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.project-bedrock-vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    aws_subnet.public-subnet-01.id,
    aws_subnet.public-subnet-02.id
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    aws_subnet.private-subnet-01.id,
    aws_subnet.private-subnet-02.id
  ]
}
