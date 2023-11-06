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
mkdir /var/www/html/website/
cd /var/www/html/
sudo git clone http://github.com/Rinkish/Sqli_Edited_Version
sudo mv /var/www/html/Sqli_Edited_Version/sqlilabs/ /var/www/html/sqli
sed -i s/localhost/$db/g /var/www/html/sqli/sql-connections/db-creds.inc # change localhost to db server ip
sed -i s/root/aws/g /var/www/html/sqli/sql-connections/db-creds.inc # change root to aws
sed -i s/\$dbpass\ \=\'\'/\$dbpass\ \=\'pass\'/g /var/www/html/sqli/sql-connections/db-creds.inc # change '' to pass
sudo systemctl restart apache2


# Installing IDS on Web Server
if [ $traffic_mirroring -ne 1 ]; then
	wget $repository_path/utils/install_ids_webserver.sh
fi