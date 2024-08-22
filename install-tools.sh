#!/bin/bash

# Update package lists
sudo apt-get update


# Install Terraform
sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install -y terraform

# install pip 
sudo apt-get install -y python3-pip
# Install Linode CLI
pip3 install linode-cli --upgrade 

# Install Ansible
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible

# Install jq 
sudo apt-get install -y jq

# Verify installations
echo "Verifying installations..."
echo "Git version: $(git --version)"
echo "Terraform version: $(terraform -v)"
echo "Linode CLI version: $(linode-cli --version)"
echo "Ansible version: $(ansible --version | head -n 1)"

echo "Installation complete."

