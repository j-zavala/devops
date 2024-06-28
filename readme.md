# Infrastructure Setup with Terraform

## Project Overview

This project sets up an infrastructure using Terraform to manage AWS resources. The key components include a Virtual Private Cloud (VPC) with public and private subnets across two availability zones, an Application Load Balancer (ALB) to distribute HTTP requests, and EC2 instances running NGINX servers in private subnets.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Components](#components)
- [Setup Instructions](#setup-instructions)
- [Usage](#usage)

## Architecture

The infrastructure architecture includes:

- **VPC and Subnets**: A VPC spanning two availability zones, each with a public and private subnet.
- **Internet Gateway and NAT Gateways**: An Internet Gateway for public subnets and NAT Gateways to enable private instances to access the internet.
- **Route Tables**: Configured route tables for managing traffic flow between subnets and the internet.
- **Security Groups**: Security groups to control inbound and outbound traffic for the ALB and EC2 instances.
- **Application Load Balancer**: An ALB to distribute HTTP requests across EC2 instances in private subnets.
- **EC2 Instances**: Two EC2 instances running NGINX servers in private subnets.

## Components

1. **VPC Configuration**
2. **Internet Gateway and NAT Gateways**
3. **Route Tables**
4. **Security Groups**
5. **Application Load Balancer**
6. **EC2 Instances**
7. **IAM Roles and Instance Profiles**

## Setup Instructions

### Prerequisites

- Terraform (>= 1.2.0)
- AWS CLI configured with appropriate permissions

### Steps

1. **Clone the Repository**
   ```sh
   git clone https://github.com/j-zavala/devops.git
   cd devops
   git checkout week-3-completed
   ```

2. **Initialize Terraform**
   ```sh
   terraform init
   ```

3. **Plan the Infrastructure**
   ```sh
   terraform plan
   ```

4. **Apply the Configuration**
   ```sh
   terraform apply
   ```

## Usage

Once the infrastructure is set up, you can access the web application via the ALB's DNS name. The ALB will distribute incoming HTTP requests to the NGINX servers running on the private EC2 instances.
