# AWS Region
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# VPC and Subnet CIDR Blocks
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_az1" {
  description = "CIDR block for the public subnet in AZ1"
  type        = string
  default     = "10.0.1.0/24"  # Change if necessary
}

variable "public_subnet_cidr_az2" {
  description = "CIDR block for the public subnet in AZ2"
  type        = string
  default     = "10.0.2.0/24"  # Change if necessary
}

# EC2 Variables
variable "ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0ebfd941bbafe70c6"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"
}

# EKS Variables
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}
