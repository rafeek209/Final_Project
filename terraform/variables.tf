variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Change to your preferred region
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16" # Change CIDR as needed
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24" # Change CIDR as needed
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
  default     = "us-east-1a" # Change as needed
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
  default     = "ami-0866a3c8686eaeeba"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}