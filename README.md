Lab Manual: Building a CI/CD Pipeline with Docker, Terraform, Kubernetes, and Jenkins
Overview

This manual provides step-by-step instructions on setting up a CI/CD pipeline for deploying Docker containers using Terraform for infrastructure provisioning, MicroK8s Kubernetes for container orchestration, and Jenkins for automation. This setup deploys an application with a frontend and backend using Docker images.
Prerequisites

    Basic knowledge of Docker, Terraform, Kubernetes, and Jenkins.
    GitHub account for source code and version control.
    Docker Hub account for storing Docker images.
    Azure account for creating virtual machines.

Steps
1. Set Up Docker Containers
Step 1.1: Create Dockerfiles for Frontend and Backend and Database

In the client and server directories of your application, create Dockerfiles to define how each part of your application is containerized. Ensure each Dockerfile installs necessary dependencies and sets up the entry point.

Example Dockerfile:

Dockerfile

# Use an official base image
FROM node:14

# Set working directory
WORKDIR /app

# Copy and install dependencies
COPY . .
RUN npm install

# Expose application port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]

Step 1.2: Build and Push Docker Images to Docker Hub

    Build the Docker images:

    bash

docker build -t your-dockerhub-username/your-app:frontend ./client
docker build -t your-dockerhub-username/your-app:backend ./server

Log in to Docker Hub:

bash

docker login

Push images to Docker Hub:

bash

    docker push your-dockerhub-username/your-app:frontend
    docker push your-dockerhub-username/your-app:backend

2. Provision Infrastructure with Terraform on Azure
Step 2.1: Set Up Terraform Configuration

    Initialize your main.tf to provision an Azure VM:

    hcl

    provider "azurerm" {
      features {}
    }

    resource "azurerm_resource_group" "microk8s_rg" {
      name     = "microk8s_rg"
      location = "West US"
    }

    resource "azurerm_virtual_network" "microk8s_vnet" {
      name                = "microk8s_vnet"
      address_space       = ["10.0.0.0/16"]
      location            = azurerm_resource_group.microk8s_rg.location
      resource_group_name = azurerm_resource_group.microk8s_rg.name
    }

    resource "azurerm_subnet" "microk8s_subnet" {
      name                 = "microk8s_subnet"
      resource_group_name  = azurerm_resource_group.microk8s_rg.name
      virtual_network_name = azurerm_virtual_network.microk8s_vnet.name
      address_prefixes     = ["10.0.1.0/24"]
    }

    resource "azurerm_public_ip" "microk8s_ip" {
      name                = "microk8s_ip"
      location            = azurerm_resource_group.microk8s_rg.location
      resource_group_name = azurerm_resource_group.microk8s_rg.name
      allocation_method   = "Static"
    }

    resource "azurerm_network_interface" "microk8s_nic" {
      name                = "microk8s_nic"
      location            = azurerm_resource_group.microk8s_rg.location
      resource_group_name = azurerm_resource_group.microk8s_rg.name

      ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.microk8s_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.microk8s_ip.id
      }
    }

    resource "azurerm_linux_virtual_machine" "microk8s_vm" {
      name                = "microk8s-vm"
      resource_group_name = azurerm_resource_group.microk8s_rg.name
      location            = azurerm_resource_group.microk8s_rg.location
      size                = "Standard_B2s"
      admin_username      = "azureuser"

      network_interface_ids = [
        azurerm_network_interface.microk8s_nic.id,
      ]

      os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
      }

      source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
      }

      admin_ssh_key {
        username   = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
      }

      computer_name  = "microk8s-vm"
      disable_password_authentication = true
    }

Step 2.2: Apply Terraform Configuration

    Initialize and apply Terraform configuration:

    bash

    terraform init
    terraform apply

    Add NSG Rules for ports 30001 and 30002 in your main.tf as needed to allow access to the Kubernetes services.

3. Install MicroK8s and Deploy Kubernetes Resources
Step 3.1: SSH into Azure VM and Install MicroK8s

    SSH into your Azure VM:

    bash

ssh azureuser@<VM_PUBLIC_IP>

Install MicroK8s:

bash

sudo snap install microk8s --classic

Add MicroK8s User to Docker Group:

bash

    sudo usermod -aG microk8s $USER
    newgrp microk8s

Step 3.2: Transfer and Apply Kubernetes YAML Files

    Copy Kubernetes YAML files for your application to the Azure VM.
    Apply the YAML files:

    bash

    microk8s kubectl apply -f frontend-deployment.yaml
    microk8s kubectl apply -f backend-deployment.yaml

4. Set Up Jenkins for CI/CD Pipeline
Step 4.1: Install Jenkins Locally and Configure Credentials

    Install Jenkins and access it at http://localhost:8080.
    Add Docker Hub and SSH credentials in Jenkins under Manage Jenkins > Manage Credentials.

Step 4.2: Create a Jenkins Pipeline

    Create a new pipeline job in Jenkins.
    Define a Jenkinsfile with the following stages:
        Checkout Code: Pulls latest code from GitHub.
        Build Docker Images: Builds frontend and backend Docker images.
        Push Docker Images: Pushes images to Docker Hub.
        Deploy to Azure VM: SSHs into the VM to update the MicroK8s deployments.

Example Jenkinsfile snippet:

groovy

pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        SSH_CREDENTIALS = 'azure-ssh-credentials'
        FRONTEND_IMAGE = 'your-dockerhub-username/frontend-basic'
        BACKEND_IMAGE = 'your-dockerhub-username/backend-image'
        GITHUB_REPO = 'your-github-username/your-repo-name'
        VM_IP = '<VM_PUBLIC_IP>'
    }

    stages {
        stage('Checkout Code') { steps { git url: "https://github.com/${GITHUB_REPO}.git" } }
        stage('Build Docker Images') { steps { /* build steps here */ } }
        stage('Push Docker Images') { steps { /* push steps here */ } }
        stage('Deploy to MicroK8s') { steps { /* SSH and kubectl set image commands */ } }
    }
}

Step 4.3: Test the Pipeline

Trigger the pipeline and ensure that it:

    Pulls code, builds, and pushes Docker images.
    Deploys the updated images to MicroK8s on the Azure VM.

Conclusion

This guide provides a step-by-step process to set up a CI/CD pipeline that builds, pushes, and deploys Docker containers to a Kubernetes environment on an Azure VM using Terraform and Jenkins.