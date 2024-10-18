
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

1. Main Terraform File: main.tf

This file typically defines the main infrastructure components for AWS, such as the VPC, subnets, EC2 instances, and Kubernetes cluster (EKS). Below is an example breakdown.
main.tf

hcl

# Specify the AWS provider and region
provider "aws" {
  region = "us-west-2"  # Specify the AWS region
}

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "public-subnet"
  }
}

# Create an Internet Gateway to allow traffic
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Create a route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security group to allow SSH and HTTP access to EC2
resource "aws_security_group" "allow_ssh_http" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

# Create an EC2 instance for the application
resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.allow_ssh_http.name]

  tags = {
    Name = "AppServer"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y docker.io
  EOF
}

Explanation of Each Section:

    provider "aws":
        Defines the AWS provider and specifies the region (us-west-2 in this case) where the resources will be deployed.

    VPC Creation:
        resource "aws_vpc" "main":
            Creates a Virtual Private Cloud (VPC), which is a logically isolated network in AWS. The cidr_block 10.0.0.0/16 defines the IP range for the VPC, meaning it can contain up to 65,536 IP addresses.

    Public Subnet:
        resource "aws_subnet" "public":
            Defines a subnet within the VPC. This subnet will contain the EC2 instance, and the cidr_block 10.0.1.0/24 allows up to 256 IP addresses.
            The availability_zone ensures the subnet is created in a specific zone (e.g., us-west-2a).

    Internet Gateway:
        resource "aws_internet_gateway" "igw":
            Creates an Internet Gateway, which allows the VPC to connect to the internet. It is necessary to give the EC2 instance internet access (for updates and other actions).

    Route Table:
        resource "aws_route_table" "public":
            Creates a route table for the public subnet, allowing traffic to route to and from the internet via the Internet Gateway.
        resource "aws_route_table_association" "public_association":
            Associates the route table with the public subnet to enable internet routing for the subnet.

    Security Group:
        resource "aws_security_group" "allow_ssh_http":
            Defines a security group, which acts as a virtual firewall for your instance.
            ingress rules allow incoming traffic:
                Port 22 (SSH): Allows SSH access from any IP address (0.0.0.0/0).
                Port 80 (HTTP): Allows HTTP access from any IP address.
            egress rule allows all outgoing traffic from the instance.
            Security groups are essential for defining what traffic is allowed into and out of your EC2 instances.

    EC2 Instance:
        resource "aws_instance" "app_server":
            Defines an EC2 instance, which acts as the server for your application.
            The ami (Amazon Machine Image) specifies the operating system for the instance (Ubuntu in this case).
            instance_type (t2.micro): Defines the type of instance, which determines the CPU and memory (t2.micro is a free-tier eligible option).
            subnet_id: Associates the instance with the public subnet, enabling it to have internet access.
            security_groups: Attaches the security group created earlier, which allows SSH and HTTP traffic to the instance.
            user_data: This section provides a script that runs when the EC2 instance is first launched. In this case, the script updates the instance and installs Docker, preparing the instance to run Docker containers.

2. Variables File: variables.tf

Variables are used to make the Terraform configuration more flexible and reusable.
variables.tf

hcl

# AWS region
variable "region" {
  description = "The AWS region to deploy resources."
  default     = "us-west-2"
}

# EC2 instance type
variable "instance_type" {
  description = "Type of EC2 instance to use."
  default     = "t2.micro"
}

# VPC CIDR block
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

# Subnet CIDR block
variable "subnet_cidr" {
  description = "CIDR block for the public subnet."
  default     = "10.0.1.0/24"
}

Explanation:

    Variables:
        The variables.tf file defines default values for certain parameters, such as the AWS region, EC2 instance type, and CIDR blocks for the VPC and subnets.
        This allows you to customize the infrastructure without changing the main configuration files. For example, you could modify the region or instance type by overriding these variables when running Terraform commands.

3. Outputs part:

This file defines what information should be outputted after Terraform successfully creates the infrastructure.
outputs.tf

hcl

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.app_server.public_ip
}

output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "The ID of the public subnet."
  value       = aws_subnet.public.id
}

Explanation:

    Outputs:
        Terraform outputs are displayed after the infrastructure is provisioned. These provide useful information, such as the public IP address of the EC2 instance, which you need to access it via SSH or HTTP.
        instance_public_ip outputs the public IP of the EC2 instance, allowing you to connect to it after provisioning.
        vpc_id and subnet_id output the IDs of the created VPC and subnet, which may be helpful for future Terraform steps or debugging.

4. Modules for EKS (Kubernetes)

If you are using Kubernetes, you would likely have a module setup for EKS in a file like eks.tf. Here’s an example of what it might contain:
eks.tf

hcl

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "my-cluster"
  cluster_version = "


### 2. Infrastructure Configuration with Ansible

**Purpose**: To configure the EC2 instance and deploy Jenkins as part of the CI/CD pipeline.

#### a. Ansible Playbook for Jenkins Installation

Ansible is used to automate the installation of Jenkins on the EC2 instance. The playbook installs Jenkins on the app server.

```yaml
---
- hosts: app_server
  become: yes
  tasks:
    - name: Update APT repository
      apt:
        update_cache: yes

    - name: Install required dependencies
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - git
        - curl
        - apt-transport-https
        - ca-certificates
        - software-properties-common

    - name: Add Docker GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker APT repository
      apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable
        state: present

    - name: Install Docker
      apt:
        name: docker-ce
        state: present
        update_cache: yes

    - name: Add Jenkins repository key to the system
      apt_key:
        url: https://pkg.jenkins.io/debian/jenkins.io.key
        state: present

    - name: Add Jenkins APT repository to sources list
      apt_repository:
        repo: deb http://pkg.jenkins.io/debian-stable binary/
        state: present

    - name: Install Jenkins
      apt:
        name: jenkins
        state: present

    - name: Start Jenkins service
      systemd:
        name: jenkins
        state: started
        enabled: yes

```
Explanation of Each Section

    hosts: app_server:
        This specifies the target group (defined in the inventory file) for the playbook. app_server typically refers to the EC2 instance where Jenkins and Docker need to be installed.

    become: yes:
        This allows Ansible to execute the tasks with elevated (root) privileges, which is essential for installing software or making system-level changes.

    Tasks:
        Ansible tasks are individual steps that are executed sequentially. Each task has a descriptive name, which helps in understanding what it does when you run the playbook.

    Task 1: Update APT repository:
        apt update_cache updates the package list on the Ubuntu system, ensuring the latest versions of packages are available for installation.

    Task 2: Install required dependencies:
        This task installs several essential dependencies like git, curl, and ca-certificates using the apt module.
        loop: The loop runs through a list of items (dependencies) and installs them one by one.

    Task 3: Add Docker GPG key:
        To ensure the integrity of Docker packages, this task adds Docker’s official GPG key to the system's keyring, verifying that the downloaded Docker packages are legitimate.

    Task 4: Add Docker APT repository:
        This adds Docker’s official APT repository to the system, allowing the installation of Docker packages via APT.

    Task 5: Install Docker:
        Installs Docker using the docker-ce package. The update_cache: yes ensures the system's package index is updated before the installation begins.

    Task 6: Add Jenkins repository key:
        This adds the GPG key for Jenkins, verifying that the Jenkins packages are safe to install.

    Task 7: Add Jenkins APT repository:

    Adds Jenkins' official APT repository to the system so that the Jenkins package can be installed through APT.

    Task 8: Install Jenkins:

    Installs Jenkins using the package manager (apt).

    Task 9: Start Jenkins service:

    Starts Jenkins as a background service using systemd. This task also ensures that Jenkins will start automatically upon system reboot.

Inventory File (inventory)

An inventory file tells Ansible which hosts to target. Based on the Terraform provisioning, the EC2 public IP would be included here.

Example inventory file:

ini

[app_server]
<EC2_PUBLIC_IP> ansible_ssh_user=ubuntu ansible_ssh_private_key_file=~/.ssh/private_key

Explanation of Inventory:

    [app_server]: This is the name of the host group. It corresponds to the hosts: app_server in the playbook.
    <EC2_PUBLIC_IP>: The public IP of the EC2 instance where Jenkins will be installed.
    ansible_ssh_user=ubuntu: The default user for Ubuntu instances on AWS is usually ubuntu.
    ansible_ssh_private_key_file=~/.ssh/private_key: This points to the private key file for authenticating with the EC2 instance over SSH.

Additional Notes:

    Why Use Ansible for Jenkins Installation?
        Automating the Jenkins installation with Ansible ensures that the process is consistent and repeatable. You avoid manually installing Jenkins and its dependencies each time, which saves time and reduces human error.

    Docker Installation in Ansible:
        Docker is installed on the EC2 instance as part of the containerization process. This setup is crucial for running the containerized application that will be deployed later in the CI/CD pipeline.

    Handling Configuration Files:
        If additional configurations (like Jenkins credentials or plugins) need to be set up, you can add more tasks to the playbook. For example, you could copy over a config.xml file to Jenkins using the copy module.

    Running the Playbook:
        Once the playbook is ready, you can run it using the following command:

        bash

        ansible-playbook -i inventory playbook.yml

    This command will execute all the tasks defined in the playbook on the app_server host (EC2 instance).

By using Ansible, you streamline the process of configuring Jenkins and Docker on your AWS infrastructure, ensuring consistent and scalable deployments

1. GitHub Repository Setup

Your GitHub repository is essential for managing the version control of your project and integrating it with Jenkins for Continuous Integration (CI) and Continuous Deployment (CD). The steps involved in setting up your repository include:
a. Repository Structure

Typically, your repository will have the following structure:

css

Final_Project/
├── Dockerfile
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
├── ansible/
│   ├── playbook.yml
├── kubernetes/
│   ├── deployment.yaml
│   ├── service.yaml
├── jenkins/
│   ├── Jenkinsfile
└── src/
    ├── app.py
    ├── requirements.txt

    Dockerfile: Used to build the Docker image of the application.
    Terraform: For Infrastructure as Code (IaC), to provision resources like EC2 instances, security groups, VPC, etc.
    Ansible: For automating the installation and configuration of services (e.g., Jenkins).
    Kubernetes: To define deployment and service files for Kubernetes, handling container orchestration.
    Jenkinsfile: Defines the CI/CD pipeline in Jenkins.
    Source Code (src/): Contains your web application, app.py, which gets deployed.

b. Branches: Dev and Prod

You should create two branches to separate development and production environments:

    Dev: Used for development, integrating and testing new features.
    Prod: Used for stable releases, only merging here when the features are fully tested and ready for deployment.

c. Webhooks in GitHub

    Webhook Setup: You will configure a GitHub webhook to trigger Jenkins builds automatically whenever there is a push to the repository.
        This ensures every change in the Dev branch triggers a deployment to the development environment in Kubernetes, while pushes to the Prod branch trigger production deployments.

2. Dockerfile

The Dockerfile is a crucial part of the project as it defines the application’s container environment, allowing consistent deployment across different environments.
Dockerfile Example:

dockerfile

# Use an official Ubuntu image as the base
FROM ubuntu:latest

# Update the package manager and install Python3
RUN apt-get update && apt-get install -y python3

# Copy the application code to the container
COPY . /app

# Set the working directory to /app
WORKDIR /app

# Expose port 80 for the application
EXPOSE 80

# Run the application
CMD ["python3", "app.py"]

Explanation:

    Base Image:
        FROM ubuntu:latest: Uses Ubuntu as the base image.

    Package Installation:
        RUN apt-get update && apt-get install -y python3: Installs Python3 in the container, required for running the Python application.

    Application Code:
        COPY . /app: Copies the entire application code from your GitHub repository to the container.

    Working Directory:
        WORKDIR /app: Sets the /app directory as the current working directory inside the container.

    Expose Ports:
        EXPOSE 80: Exposes port 80 to make the application accessible via HTTP.

    Command:
        CMD ["python3", "app.py"]: Specifies the default command to run the Python app when the container starts.

3. Jenkins Configuration

Jenkins is the automation tool used for CI/CD. It pulls code from GitHub, builds it using Docker, and deploys it to the Kubernetes cluster.
a. Jenkins Setup on EC2

    Access Jenkins:
        Once Jenkins is installed and running, you can access its web interface at: http://3.91.57.215:8080.
    Initial Setup:
        On first access, Jenkins will ask for an initial password (located at /var/lib/jenkins/secrets/initialAdminPassword on the EC2 instance). This unlocks Jenkins and initiates the setup wizard.
        Choose to install the suggested plugins (GitHub, Docker, etc.).
    Admin User Setup:
        During the wizard, you'll create an admin user for Jenkins to manage the pipelines and projects.

b. Configuring Jenkins Credentials

For Jenkins to integrate with DockerHub, GitHub, and your AWS environment, you need to configure secure credentials.

    GitHub Credentials:
        Go to Jenkins Dashboard > Manage Jenkins > Manage Credentials.
        Add GitHub credentials (personal access token) so Jenkins can pull code from your GitHub repository.

    DockerHub Credentials:
        Add DockerHub credentials (username and password) so Jenkins can push the Docker image to your DockerHub repository.

    AWS Credentials:
        You can store AWS access and secret keys to allow Jenkins to run Terraform scripts or communicate with your AWS infrastructure.

c. Jenkinsfile for CI/CD Pipeline

The Jenkinsfile defines the CI/CD pipeline for automating the steps from code checkout to deployment.
Jenkinsfile Example:

groovy

pipeline {
    agent any
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'dev', url: 'https://github.com/rafeek209/Final_Project.git'
            }
        }
        stage('Terraform Apply') {
            steps {
                sh 'terraform init'
                sh 'terraform apply -auto-approve'
            }
        }
        stage('Ansible Configuration') {
            steps {
                sh 'ansible-playbook -i inventory playbook.yml'
            }
        }
        stage('Docker Build and Push') {
            steps {
                script {
                    docker.build('my_app_image').push('my_app_image:latest')
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f kubernetes/deployment.yaml'
                sh 'kubectl apply -f kubernetes/service.yaml'
            }
        }
    }
}

Explanation:

    Checkout Code:
        Jenkins pulls the latest code from the dev branch in the GitHub repository.

    Terraform Apply:
        Initializes and applies Terraform to provision or update AWS infrastructure.

    Ansible Configuration:
        Executes the Ansible playbook to install and configure services like Docker or Jenkins itself on the EC2 instance.

    Docker Build and Push:
        Builds the Docker image of the application and pushes it to DockerHub.

    Deploy to Kubernetes:
        Applies the Kubernetes deployment and service files to deploy the Docker container into the Kubernetes cluster.

4. Docker in Docker (DinD) Explanation

In your Jenkins pipeline, you use Docker to build a container inside a Jenkins pipeline, which itself may be running inside a Docker container (Docker-in-Docker).
Why Use Docker-in-Docker?

    Isolation:
        Using Docker-in-Docker allows Jenkins to build and run Docker containers in an isolated environment without interfering with the host’s Docker instance.

    Consistency Across Environments:
        This setup ensures that Jenkins pipelines can build Docker images the same way on any Jenkins agent, ensuring a consistent CI/CD environment regardless of where the Jenkins server is running.

    Portability:
        You can easily move Jenkins and its pipelines to any environment (EC2, on-premises, Kubernetes) without worrying about the underlying system's Docker version.

    Containerized Builds:
        Building Docker images inside a Docker container is a common pattern in modern CI/CD pipelines to ensure that the Jenkins agents are stateless and lightweight.

Considerations for Docker-in-Docker:

    Performance: Running Docker containers inside other containers can slightly degrade performance, though this is usually not an issue in CI/CD pipelines.
    Security: Ensure proper security measures are in place to avoid any container breakout scenarios, though Jenkins is generally used in controlled environments.

5. Jenkins Login URL

    You can access your Jenkins server at http://3.91.57.215:8080. Ensure your EC2 security group allows inbound traffic on port 8080, and use the initial admin password to set up your Jenkins admin account.

1. Kubernetes (K8s) Files and Configuration

In your project, Kubernetes is used to orchestrate the deployment and management of containerized applications. The following configuration files define how your application is deployed and exposed in the Kubernetes cluster.
a. Deployment File

This file defines how the application is deployed within the Kubernetes cluster, including the Docker image it uses, the number of replicas, and other essential parameters.
deployment.yaml Example:

yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-deployment
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
        image: my_app_image:latest
        ports:
        - containerPort: 80

Explanation:

    apiVersion & kind:
        apiVersion: apps/v1 and kind: Deployment: This defines the type of Kubernetes resource (in this case, a Deployment).

    Metadata:
        name: my-app-deployment: The name of the deployment.
        namespace: dev: This places the deployment in the Dev namespace, which helps isolate different environments (Dev vs. Prod) within the same Kubernetes cluster.

    Replicas:
        replicas: 2: Specifies that Kubernetes should run 2 replicas of the application for load balancing and high availability.

    Selector:
        matchLabels: Specifies that this deployment should manage pods with the label app: my-app.

    Pod Template:
        This section defines the configuration of the pods created by the deployment. Each pod runs the Docker container specified in the containers section.

    Containers:
        name: my-app: The name of the container inside the pod.
        image: my_app_image:latest: Specifies the Docker image to be used. The image is built and pushed by Jenkins during the CI/CD pipeline.
        ports: Exposes the application running inside the container on port 80.

This deployment file tells Kubernetes to maintain two running instances of your application, based on the Docker image my_app_image:latest.
b. Service File

The service file exposes your application to external traffic by using a LoadBalancer. It also handles internal communication between different pods or microservices within the cluster.
service.yaml Example:

yaml

apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: dev
spec:
  selector:
    app: my-app
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

Explanation:

    apiVersion & kind:
        apiVersion: v1 and kind: Service: Defines a Kubernetes Service, which is responsible for exposing the deployment externally.

    Metadata:
        name: my-app-service: The name of the service.
        namespace: dev: Like the deployment, this service is in the Dev namespace, managing traffic for the development environment.

    Selector:
        app: my-app: This selector links the service to the pods created by the deployment with the label app: my-app.

    Service Type:
        type: LoadBalancer: This exposes the application to external traffic. In a cloud environment like AWS, this creates an AWS Elastic Load Balancer (ELB) to route traffic to the application.

    Ports:
        port: 80: The port on which the service listens (external port).
        targetPort: 80: The port on which the application inside the container is running.

This service configuration enables external users to access the application running inside the Kubernetes pods via an external IP address provided by the LoadBalancer.
c. Namespaces for Dev and Prod

Kubernetes namespaces are used to organize and isolate resources within the cluster. You’ve created separate namespaces for development (dev) and production (prod), allowing you to keep your environments isolated within the same cluster.
namespace.yaml Example:

yaml

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

    Namespace Creation:
        apiVersion: v1 and kind: Namespace: This resource defines a Kubernetes Namespace.
        name: dev and name: prod: These are the two namespaces that separate the development and production environments.

Namespaces provide logical separation of resources, making it easier to manage and control the lifecycle of your application in different environments. For example, you can have different configurations for deployments and services in Dev versus Prod while still using the same Kubernetes cluster.
2. GitHub Webhook Configuration

The GitHub Webhook is a critical step for automating your CI/CD pipeline. It allows GitHub to automatically notify Jenkins whenever there is a code change in the repository (like a push or pull request), triggering the Jenkins pipeline to run and deploy the new code.
a. Why Use Webhooks?

    Without webhooks, Jenkins would need to constantly poll GitHub to check for new commits, which is inefficient.
    Webhooks provide real-time communication, allowing Jenkins to react immediately when a developer pushes code to GitHub.

b. Webhook Setup in GitHub

    Navigate to the Repository:
        Go to your repository on GitHub (e.g., https://github.com/rafeek209/Final_Project).

    Access Settings:
        Click on the Settings tab at the top of the repository page.

    Add a Webhook:
        In the left sidebar, click on Webhooks.
        Click the Add webhook button.

    Webhook URL:
        In the Payload URL field, enter your Jenkins URL followed by /github-webhook/, like so:

        arduino

        http://<JENKINS_IP>:8080/github-webhook/

        This tells GitHub to send payloads to your Jenkins instance whenever changes occur in the repository.

    Content Type:
        Set the Content Type to application/json.

    Triggers:
        In the Which events would you like to trigger this webhook? section, select Just the push event (or customize it further if needed).

    Save:
        Click Add Webhook.

Now, every time you push a new commit to the repository (in the dev or prod branch), GitHub will trigger the webhook, notifying Jenkins to start the build process.
c. Configuring Jenkins to Respond to Webhook

    Install GitHub Plugin in Jenkins:
        Ensure the GitHub Plugin is installed in Jenkins. You can do this by navigating to Manage Jenkins > Manage Plugins and searching for the GitHub Plugin.

    Set Up Jenkins Job for Webhooks:
        In your Jenkins job configuration (or pipeline), ensure you’ve selected GitHub hook trigger for GITScm polling in the Build Triggers section.

    Handling the Webhook in Jenkins:
        When a webhook is received, Jenkins will pull the latest code from the branch specified in your Jenkinsfile (e.g., dev or prod), build the Docker container, and deploy it to the Kubernetes cluster.
