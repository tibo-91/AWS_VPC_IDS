#!/bin/bash

# Retrieves command parameters
while getopts k:b:c:t: flag
do
	case "${flag}" in
		k) keyname=${OPTARG};;
		b) db_ipv4=${OPTARG};;
		c) config_db_script=${OPTARG};;
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
ssh-add /home/ubuntu/.ssh/$keyname

# Configure DB Server
echo -e "\n- Sending configuration script to the DB Server $web_server_id"
scp -i /home/ubuntu/.ssh/$keyname $config_db_script ec2-user@$db_ipv4:~/
ssh -i /home/ubuntu/.ssh/$keyname -t ec2-user@$db_ipv4 "\
    	sudo chmod +x $config_db_script; \
    	sudo bash $config_db_script"

# Configure test site
mkdir /var/www/html/website/
cd /var/www/html/
sudo git clone http://github.com/Rinkish/Sqli_Edited_Version
sudo mv /var/www/html/Sqli_Edited_Version/sqlilabs/ /var/www/html/sqli
sed -i s/localhost/$db_ipv4/g /var/www/html/sqli/sql-connections/db-creds.inc 					  # change localhost to DB Server IP
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