#!/bin/bash

sudo yum install httpd -y
sudo systemctl start httpd 
echo "Welcome from VPC2" >> "/var/www/html/index.html"