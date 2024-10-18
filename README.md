# Final Project: DevOps Automation on AWS

## Project Overview
This project demonstrates the integration of various DevOps tools and practices, including Terraform, Ansible, Docker, Jenkins, and Kubernetes, to automate the deployment and configuration of an application on AWS EC2 instances.

## Tools Used
- **Terraform**: Infrastructure as Code (IaC) tool to provision AWS resources.
- **Ansible**: Configuration management tool for application deployment.
- **Docker**: Containerization platform to package the application.
- **Jenkins**: Continuous Integration and Continuous Deployment (CI/CD) tool to automate the build and deployment process.
- **Kubernetes (K8s)**: Container orchestration platform to manage and deploy containerized applications.

## Step-by-Step Process

### 1. Infrastructure Creation with Terraform
**Purpose**: Provision the necessary AWS infrastructure for deploying the application.

#### a. Create a VPC
Terraform sets up a Virtual Private Cloud (VPC) with a public subnet to host the EC2 instance.
```hcl
provider "aws" {
  region = "us-west-2"
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

    Explanation:
        The VPC provides an isolated network.
        The subnet segments the network, enabling efficient resource management.

b. Create an EC2 Instance

Provision an EC2 instance within the public subnet, enabling internet access and installing Docker.

resource "aws_instance" "app_server" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  tags = {
    Name = "AppServer"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo apt-get update
  sudo apt-get install -y docker.io
  EOF
}
resource "aws_security_group" "allow_http" {
  name = "allow_http"
  description = "Allow HTTP inbound traffic"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

    Explanation:
        The EC2 instance acts as the application server, with a user_data script that installs Docker.
        The security group allows inbound HTTP traffic, essential for accessing the application.

c. Create a Kubernetes Cluster

Utilize EKS (Elastic Kubernetes Service) to create a Kubernetes cluster within the same VPC.

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  cluster_name = "my-cluster"
  cluster_version = "1.21"
  subnets = [aws_subnet.public.id]
  vpc_id = aws_vpc.main.id
}

    Explanation:
        EKS manages Kubernetes clusters on AWS, simplifying the process of creating and managing clusters.

2. Infrastructure Configuration with Ansible

Purpose: Configure the EC2 instance and deploy the application.
Install Jenkins

Automate the installation of Jenkins on the EC2 instance using an Ansible playbook.

- hosts: app_server
  become: yes
  tasks:
    - name: Install Jenkins
      apt:
        name: jenkins
        state: present

    Explanation:
        Ansible playbooks automate server configuration. This playbook installs Jenkins, facilitating CI/CD processes.

3. Prepare GitHub Repository

Set up a GitHub repository containing the source code for the web project.
Create Branches

Create two branches: Dev and Prod to separate development and production environments.
Write a Dockerfile

Containerize your web project with the following Dockerfile.

FROM ubuntu:latest
RUN apt-get update && apt-get install -y python3
COPY . /app
WORKDIR /app
CMD ["python3", "app.py"]

    Explanation:
        The Dockerfile defines the application environment, installs Python, and copies the application code into the container.

Prepare Kubernetes Deployment Files

Create deployment and service files for Kubernetes.

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my_app_image
        ports:
        - containerPort: 80

    Explanation:
        The deployment file defines how the application is deployed in Kubernetes, including replicas and the Docker image to use.

4. Kubernetes Configuration

Purpose: Set up the Kubernetes environment with separate namespaces for Dev and Prod.
Create Namespaces

Define two namespaces in your Kubernetes cluster.

apiVersion: v1
kind: Namespace
metadata:
  name: dev
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod

    Explanation:
        Namespaces help separate environments within the same Kubernetes cluster.

Use a Load Balancer

Expose your application externally for both namespaces.

apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: dev
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80

    Explanation:
        The service file defines how to expose the application to the outside world, using a LoadBalancer service type.

5. CI/CD Pipeline with Jenkins

Purpose: Automate the CI/CD process by configuring Jenkins.
Create Jenkins Pipelines

Define pipelines for both the Dev and Prod branches.

pipeline {
  agent any
  stages {
    stage('Terraform Apply') {
      steps {
        sh 'terraform apply -auto-approve'
      }
    }
    stage('Ansible Playbook') {
      steps {
        sh 'ansible-playbook -i inventory playbook.yml'
      }
    }
    stage('Docker Build and Run') {
      steps {
        sh 'docker build -t my_app_image .'
        sh 'docker run -d -p 80:80 my_app_image'
      }
    }
  }
}

    Explanation:
        Jenkins pipelines automate the CI/CD process, applying Terraform configurations, executing Ansible playbooks, and building/running Docker containers.

Set Up GitHub Webhook

Configure Jenkins to trigger deployments upon push events:

    For the Dev branch, deploy to the Dev Kubernetes namespace.
    For the Prod branch, deploy to the Prod Kubernetes namespace.

Tricky Points to Note

    Docker in Docker with Ansible: When using Docker in Ansible, ensure the Docker service is running on the EC2 instance. You may need to configure the Ansible playbook to handle Docker networking and permissions properly.
    Allowing HTTP Traffic in EC2 Security Groups: This is crucial for accessing the application. Without this configuration, external requests will be blocked, preventing users from reaching the application.
    Passing EC2 Public IP Address to Ansible: Ensure you capture the EC2 instance’s public IP address after provisioning. This address is needed in the Ansible inventory file to target the correct instance.
    Kubernetes Namespaces: Using namespaces helps in managing different environments (Dev and Prod) within the same cluster, ensuring isolation and resource management.
    Load Balancer Configuration: Properly configuring the LoadBalancer service type in Kubernetes is essential for exposing the application to external traffic.

GUI Steps

Certain configuration steps (e.g., setting up Jenkins, configuring credentials) cannot be captured in the repository. Document these steps clearly:

    Jenkins Setup:
        Install Jenkins on the EC2 instance using the Ansible playbook.
        Access the Jenkins web UI (http://<EC2_PUBLIC_IP>:8080).
        Complete the initial setup wizard by installing recommended plugins and configuring an admin user.
    Credentials Configuration:
        Store DockerHub and GitHub credentials securely in Jenkins to allow automated deployments.

Commands Summary

    Terraform Commands:
        terraform init: Initialize the Terraform working directory.
        terraform plan: Create an execution plan.
        terraform apply: Apply the changes required to reach the desired state.
    Ansible Commands:
        ansible-playbook -i inventory playbook.yml: Run the specified Ansible playbook.
    Docker Commands:
        docker build -t my_app_image .: Build the Docker image.
        docker run -d -p 80:80 my_app_image: Run the Docker container.
