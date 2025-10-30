#!/bin/bash

sudo -i
set -eux  # Exit on error and print each command

# Update packages
sudo apt update -y

# Install Java
sudo apt install -y openjdk-17-jdk
java -version

# Add Jenkins repo key and source list
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update -y
sudo apt install -y jenkins

# Enable and start Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Verify status
sudo systemctl status jenkins || true
