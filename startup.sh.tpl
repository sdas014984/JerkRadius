#!/bin/bash
echo "Hello from ${hostname}!" > /tmp/startup.log
sudo apt update -y
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
