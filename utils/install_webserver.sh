#!/bin/bash

config_file=config.ini

# Read configuration file
if [ -f $config_file ]; then
    source $config_file
else
    echo "Error: Configuration file $config_file not found."
    exit 1
fi

# Retrieves command parameters
while getopts k:b: flag
do
	case "${flag}" in
		k) key=${OPTARG};;
		b) db=${OPTARG};;
	esac
done

# Install Web Server packages
sudo apt update -y
sudo apt upgrade -y
sudo apt install apache2 -y
sudo apt install php -y
sudo apt install php-mysql -y
sudo systemctl start apache2

# Create and configure SSH Daemon
eval $(ssh-agent -s)
ssh-add /home/ubuntu/.ssh/$key

# Configure DB Server
ssh -i /home/ubuntu/.ssh/$key \
    -t ec2-user@$db "wget $repository_path/utils/install_dbserver.sh; \
    	sudo chmod +x ./install_dbserver.sh; \
    	sudo bash ./install_dbserver.sh"

# Configure test site
mkdir /var/www/html/website/
wget $repository_path/utils/index.php -P /var/www/html/website
sed -i s/CUSTOM_IP/$db/g /var/www/html/website/index.php
sudo systemctl restart apache2