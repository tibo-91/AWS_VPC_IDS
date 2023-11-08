#!/bin/bash

# Install Web Server packages
sudo yum update -y
#sudo yum upgrade -y
sudo yum install mariadb105-server -y
sudo systemctl start mariadb;
sudo mysql --execute "CREATE USER 'aws' IDENTIFIED BY 'pass'; GRANT ALL PRIVILEGES ON * . * TO 'aws'; FLUSH PRIVILEGES;"
echo "skip-networking=0" >> /etc/my.cnf.d/mariadb-server.cnf
echo "skip-bind-address" >> /etc/my.cnf.d/mariadb-server.cnf
sudo systemctl restart mariadb