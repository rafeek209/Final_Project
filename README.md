
# DevOps Automation on AWS

This project demonstrates the integration of various DevOps tools and practices, including Terraform, Ansible, Docker, Jenkins, and Kubernetes, to automate the deployment and configuration of an application on AWS EC2 instances. The project showcases Infrastructure as Code (IaC), configuration management, containerization, CI/CD pipelines, and container orchestration, all deployed in an AWS environment.

## Tools Used
- **Terraform**: To provision and manage AWS infrastructure (IaC).
- **Ansible**: To automate the configuration and application deployment.
- **Docker**: For containerizing the application.
- **Jenkins**: For setting up CI/CD pipelines that automate the build, test, and deployment process.
- **Kubernetes**: To orchestrate containerized applications and manage them across multiple environments (Dev/Prod).
  
## Project Structure

The following files and directories are included in the repository:

```bash
Final_Project/
├── ansible/
│   ├── playbook.yml        # Ansible playbook to install Jenkins
├── kubernetes/
│   ├── dev-namespace.yml   # Kubernetes namespace for development
│   ├── prod-namespace.yml  # Kubernetes namespace for production
│   ├── deployment.yml      # Kubernetes deployment and service definition
├── terraform/
│   ├── main.tf             # Terraform script to create AWS infrastructure
│   ├── variables.tf        # Terraform variable definitions
│   ├── output.tf           # Output configuration for Terraform
├── Dockerfile              # Docker configuration for building the app image
├── Jenkinsfile             # Jenkins pipeline script
└── README.md               # Project documentation
```

---


## Step-by-Step Process

### 1. Infrastructure Creation with Terraform

**Purpose**: To provision the necessary AWS infrastructure, including a VPC, subnets, and EC2 instances to host the application.

#### a. Create a VPC

The Virtual Private Cloud (VPC) is an isolated network within AWS where the infrastructure will be deployed. It is segmented into subnets for better resource management.

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
```

- **Explanation**:
  - The VPC provides an isolated environment.
  - The subnet segments the network for hosting the EC2 instance.

#### b. Provision an EC2 Instance

The EC2 instance acts as the application server. A user_data script installs Docker upon instance creation.

```hcl
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
```

- **Explanation**:
  - The EC2 instance is created in the public subnet with Docker pre-installed.
  - A security group allows inbound HTTP traffic, ensuring the app can be accessed externally.

#### c. Create a Kubernetes Cluster

We utilize Elastic Kubernetes Service (EKS) to create and manage Kubernetes clusters in AWS.

```hcl
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  cluster_name = "my-cluster"
  cluster_version = "1.21"
  subnets = [aws_subnet.public.id]
  vpc_id = aws_vpc.main.id
}
```

- **Explanation**:
  - EKS simplifies the process of deploying Kubernetes clusters, handling the heavy lifting for you.


### 2. Infrastructure Configuration with Ansible

**Purpose**: To configure the EC2 instance and deploy Jenkins as part of the CI/CD pipeline.

#### a. Ansible Playbook for Jenkins Installation

Ansible is used to automate the installation of Jenkins on the EC2 instance. The playbook installs Jenkins on the app server.

```yaml
- hosts: app_server
  become: yes
  tasks:
    - name: Install Jenkins
      apt:
        name: jenkins
        state: present
```
**Explanation**:
- **hosts**: Targets the 'app_server' group, which should contain the EC2 instance details in the Ansible inventory.
- **become: yes**: Ensures that the tasks are executed with superuser (root) privileges, necessary for installing system packages.
- **tasks**: Defines a list of tasks for Ansible to perform.
    - The task installs Jenkins using the apt package manager on an Ubuntu server.

You would also define an inventory file that contains the IP address or hostname of the EC2 instance provisioned by Terraform.


### 3. Application Code Setup in GitHub

The application's code, Dockerfile, and Kubernetes deployment files are stored in a GitHub repository. The repository uses branches to separate development and production environments.

#### a. Write a Dockerfile

The Dockerfile packages the application into a Docker container.

```Dockerfile
FROM ubuntu:latest
RUN apt-get update && apt-get install -y python3
COPY . /app
WORKDIR /app
CMD ["python3", "app.py"]
```

- **Explanation**:
  - The Dockerfile installs Python, copies the application code into the container, and runs the app using Python.


#### b. Kubernetes Deployment Files

These files define the Kubernetes deployment and services for both environments (Dev and Prod).

**Deployment File**:

```yaml
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
```

- **Explanation**:
  - The deployment file creates 2 replicas of the app container and specifies the Docker image.


**Service File**:

```yaml
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
```

- **Explanation**:
  - This service file exposes the application to external traffic via a LoadBalancer.


### 4. Kubernetes Configuration

Kubernetes namespaces are used to isolate the Dev and Prod environments. Each namespace manages its own resources, allowing for separation between development and production.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod
```

- **Explanation**:
  - Namespaces create separate environments within the same Kubernetes cluster.


### 5. CI/CD Pipeline with Jenkins

**Purpose**: To automate the continuous integration and deployment process using Jenkins pipelines.

#### Jenkins Pipeline Script

The Jenkins pipeline defines stages for provisioning infrastructure, configuring servers, and deploying applications.

```groovy
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
```

- **Explanation**:
  - The pipeline automates the Terraform, Ansible, and Docker steps, ensuring continuous deployment whenever code changes are pushed to GitHub.

#### Webhook Setup

Jenkins is configured with GitHub webhooks to trigger automatic builds and deployments whenever changes are pushed to the Dev or Prod branches.

- **Explanation**:
  - Webhooks enable Jenkins to listen for GitHub events and trigger pipelines automatically, ensuring a smooth CI/CD workflow.


---

## Key Commands

- **Terraform**:
  - `terraform init`: Initializes the Terraform workspace.
  - `terraform plan`: Previews the infrastructure changes.
  - `terraform apply`: Deploys the infrastructure changes.

- **Ansible**:
  - `ansible-playbook -i inventory playbook.yml`: Executes the Ansible playbook.

- **Docker**:
  - `docker build -t my_app_image .`: Builds the Docker image.
  - `docker run -d -p 80:80 my_app_image`: Runs the Docker container.

---

## GUI Setup for Jenkins

Some setup
