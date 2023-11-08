#!/bin/bash

# Retrieves command parameters
while getopts k:b:r:t: flag
do
	case "${flag}" in
		k) key=${OPTARG};;
		b) db=${OPTARG};;
		r) repository_path=${OPTARG};;
		t) traffic_mirroring=${OPTARG};;
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
    -t ec2-user@$db "wget $repository_path/utils/configure_dbserver.sh; \
    	sudo chmod +x ./configure_dbserver.sh; \
    	sudo bash ./configure_dbserver.sh"

# Configure test site
mkdir /var/www/html/website/
cd /var/www/html/
sudo git clone http://github.com/Rinkish/Sqli_Edited_Version
sudo mv /var/www/html/Sqli_Edited_Version/sqlilabs/ /var/www/html/sqli
sed -i s/localhost/$db/g /var/www/html/sqli/sql-connections/db-creds.inc 						  # change localhost to db server ip
sed -i s/root/aws/g /var/www/html/sqli/sql-connections/db-creds.inc 							  # change root to aws
sed -i s/\$dbpass\ \=\'\'/\$dbpass\ \=\'pass\'/g /var/www/html/sqli/sql-connections/db-creds.inc  # change '' to pass
sudo systemctl restart apache2


# Installing IDS on Web Server (log SQL injection alerts on port 80)
if [ $traffic_mirroring -ne 1 ]; then
	sudo apt install snort -y
	echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"select"; sid:1000001;)' | sudo tee -a /etc/snort/rules/local.rules
	echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"SELECT"; sid:1000002;)' | sudo tee -a /etc/snort/rules/local.rules
	echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"%27"; sid:1000003;)' | sudo tee -a /etc/snort/rules/local.rules # %27 is '
	echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"%22"; sid:1000004;)' | sudo tee -a /etc/snort/rules/local.rules # %22 is "
	sudo service snort restart
fi