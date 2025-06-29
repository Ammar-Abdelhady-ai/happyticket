#!/bin/bash

# Update system packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Python (required for Ansible)
sudo apt-get install -y python3 python3-pip

# Install SSH server
sudo apt-get install -y openssh-server



# Create a user for Ansible
# sudo useradd -m -s /bin/bash ansible_user
# echo 'ansible_user:your_password' | sudo chpasswd
# echo 'ansible_user ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers.d/ansible_user


