

---

# **Terraform GitLab CI/CD Pipeline Setup with Hello World Application**

This repository contains a Terraform-based GitLab CI/CD pipeline that creates infrastructure resources on AWS, such as EC2 instances and security groups, and sets up a basic Hello World application using Docker.

The pipeline will help you:
1. Automatically run Terraform to plan infrastructure changes.
2. Set up a simple EC2 instance with a Docker container running the Hello World application.

## **Overview**

This setup defines a GitLab CI/CD pipeline that:
- Installs Terraform on the GitLab Runner.
- Initializes Terraform.
- Runs `terraform plan` to preview infrastructure changes.
- Creates an EC2 instance running a Dockerized Hello World application.

### **Key Components**

#### **.gitlab-ci.yml**

This is the main CI/CD configuration file, which defines the stages and jobs for running Terraform commands. It installs Terraform, runs the plan, and saves the plan as an artifact for review.

#### **main.tf**

The main Terraform configuration file that:
- Defines the AWS provider.
- Creates a security group for HTTP traffic.
- Launches an EC2 instance running a Dockerized Nginx Hello World application.

---

## **Terraform Configuration**

### **main.tf**
```hcl
provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP traffic"
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
}

resource "aws_instance" "hello_world" {
  ami           = var.ami_id
  instance_type = var.instance_type
  security_groups = [aws_security_group.allow_http.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              docker run -d -p 80:80 --name hello-world nginx
              EOF

  tags = {
    Name = var.instance_name
  }
}

output "instance_public_ip" {
  value = aws_instance.hello_world.public_ip
}

output "instance_id" {
  value = aws_instance.hello_world.id
}

variable "aws_region" {
  default = "us-east-1"
}

variable "ami_id" {
  default = "ami-0c02fb55956c7d316"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_name" {
  default = "HelloWorldApp"
}
```

### **.gitlab-ci.yml**
```yaml
stages:
  - terraform

variables:
  AWS_REGION: "us-east-1"

before_script:
  - echo "Setting up environment..."
  - apk add --no-cache wget unzip
  - wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip -O terraform.zip
  - unzip terraform.zip && mv terraform /usr/local/bin/terraform
  - terraform version

terraform_plan:
  stage: terraform
  script:
    - echo "Initializing Terraform..."
    - terraform init
    - echo "Running Terraform Plan..."
    - terraform plan -refresh=false -out=plan.out
  artifacts:
    paths:
      - plan.out
    when: always
  only:
    - main
```

---

## **How It Works**

### **1. GitLab CI/CD Pipeline**

The `.gitlab-ci.yml` file defines the CI/CD pipeline that automates the process of running Terraform commands on the GitLab Runner.

- **Stages**: There is one stage called `terraform`, which is where all Terraform-related tasks are executed.
  
- **Before Script**:
  - It sets up the environment by installing `wget` and `unzip` to download and install Terraform.
  - Terraform is downloaded from the official HashiCorp release page and installed globally on the GitLab Runner.
  - The `terraform version` command checks if Terraform was installed correctly.

- **Terraform Plan Job**:
  - `terraform init` initializes Terraform by downloading the required provider plugins.
  - `terraform plan` generates the execution plan, which is saved to `plan.out`. This step allows you to preview the infrastructure changes before applying them to AWS.
  - The plan file (`plan.out`) is saved as an artifact so that you can inspect it later or use it for applying changes manually.
  - The job is triggered only when changes are made to the `main` branch.

### **2. Terraform Infrastructure Configuration**

The `main.tf` file defines the infrastructure resources you want to create on AWS. In this case, the setup will:

- **Security Group**: Allow incoming HTTP traffic on port 80.
- **EC2 Instance**: Create an EC2 instance running Amazon Linux 2, install Docker, and run an Nginx Docker container, which serves a simple "Hello World" page.
- **Outputs**: The public IP and instance ID of the created EC2 instance are outputted after the Terraform plan.

### **3. AWS Setup**

The EC2 instance uses:
- An **Amazon Linux 2 AMI** (specified by `ami-0c02fb55956c7d316`).
- A **t2.micro instance type** (suitable for testing or small applications).
- The **Hello World app** is served through a Docker container running Nginx. The Nginx container is configured to listen on port 80.

---

## **Prerequisites**

- **Terraform**: This pipeline uses Terraform to manage AWS infrastructure. The configuration expects to run Terraform 1.5.0.
- **AWS Account**: Although the pipeline runs the `terraform plan` job without applying changes, make sure you have valid AWS credentials to allow Terraform to interact with AWS services.
- **GitLab Runner**: A GitLab Runner is required to execute the jobs in `.gitlab-ci.yml`. It should have access to the internet for downloading Terraform and connecting to AWS (if applicable).

---

## **How to Use**

### **1. Clone the Repository**
Clone this repository to your local machine or directly into your GitLab environment.

```bash
git clone https://github.com/nishantpratap1/terraform-learning.git
```

### **2. Customize Variables**
Update the `main.tf` file to fit your needs. Ensure the AWS region, AMI ID, instance type, and any other relevant configurations are correct for your environment.

### **3. Push Changes to the Main Branch**
Push any changes to the `main` branch of the repository. This will trigger the GitLab CI/CD pipeline and run the Terraform plan.

```bash
git add .
git commit -m "Update Terraform configuration"
git push origin main
```

### **4. View the Generated Terraform Plan**
After the pipeline completes, you can view the Terraform plan in the GitLab CI/CD job artifacts (`plan.out`). This file will include detailed information on the changes Terraform plans to make to your AWS infrastructure.

---

## **Common Use Cases**

- **Infrastructure Validation**: Automatically validate the Terraform plan and preview changes before applying them.
- **Dry Run for Testing**: Test Terraform configurations without applying changes, useful for local environments or mock AWS setups.
- **CI/CD Integration**: Automate Terraform workflows directly in your GitLab CI/CD pipeline, ensuring that infrastructure changes are reviewed before they are applied.

---

## **Conclusion**

This repository provides a fully automated pipeline for running Terraform plans within GitLab CI/CD. It ensures that changes to your infrastructure are validated and reviewed before applying them to production, providing a simple yet powerful workflow for managing infrastructure as code with Terraform.

