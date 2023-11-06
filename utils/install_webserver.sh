#!/bin/bash



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
#mkdir /var/www/html/website/
#wget $repository_path/utils/index.php -P /var/www/html/website
#sed -i s/CUSTOM_IP/$db/g /var/www/html/website/index.php
#sudo systemctl restart apache2

# Configure test site
mkdir /var/www/html/website/
cd /var/www/html/
sudo git clone http://github.com/Rinkish/Sqli_Edited_Version
sed -i s/localhost/$db/g /var/www/html/Sqli_Edited_Version/sqlilabs/sql-connections/db-creds.inc
sed -i s/root/aws/g /var/www/html/Sqli_Edited_Version/sqlilabs/sql-connections/db-creds.inc
sed -i s/\$dbpass\ \=\'\'/\$dbpass\ \=\'pass\'/g /var/www/html/Sqli_Edited_Version/sqlilabs/sql-connections/db-creds.inc
sudo systemctl restart apache2


# install and configure snort
#sudo apt install snort -y

# Configure Snort to log SQL injection alerts on port 80
#echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"select"; sid:1000001;)' | sudo tee -a /etc/snort/rules/local.rules
#sudo service snort restart