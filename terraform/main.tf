provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "MainVPC"
  }
}

resource "aws_subnet" "public_subnet_az1" {
  vpc_id                     = aws_vpc.main_vpc.id
  cidr_block                 = var.public_subnet_cidr_az1
  map_public_ip_on_launch    = true
  availability_zone          = "${var.aws_region}a"

  tags = {
    Name = "PublicSubnetAZ1"
  }
}

resource "aws_subnet" "public_subnet_az2" {
  vpc_id                     = aws_vpc.main_vpc.id
  cidr_block                 = var.public_subnet_cidr_az2
  map_public_ip_on_launch    = true
  availability_zone          = "${var.aws_region}b"

  tags = {
    Name = "PublicSubnetAZ2"
  }
}


# Create EC2 Instance
resource "aws_instance" "EC2" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet_az1.id  # Use one of the public subnets

  tags = {
    Name = "EC2Instance"
  }
}

# Create EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.public_subnet_az1.id, aws_subnet.public_subnet_az2.id]  # Use both public subnets
  }

  tags = {
    Name = "EKSCluster"
  }
}

# IAM Role for EKS
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "EKSRole"
  }
}

# Attach EKS Policy to Role
resource "aws_iam_role_policy_attachment" "eks_policy_attachment" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Outputs
output "instance_public_ip" {
  value = aws_instance.EC2.public_ip
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}
