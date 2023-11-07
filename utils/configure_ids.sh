#!/bin/bash


# Retrieves command parameters
while getopts k:b: flag
do
	case "${flag}" in
		k) network_interface_ids_id=${OPTARG};;
	esac
done
echo -e "\n\n\n$network_interface_ids_id\n\n\n"

sudo apt update -y
sudo apt upgrade -y
sudo apt install snort -y

# specify the interface to listen on
# <here>

echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"select"; sid:1000001;)' | sudo tee -a /etc/snort/rules/local.rules
echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"SELECT"; sid:1000002;)' | sudo tee -a /etc/snort/rules/local.rules
echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"%27"; sid:1000003;)' | sudo tee -a /etc/snort/rules/local.rules # %27 is '
echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"%22"; sid:1000004;)' | sudo tee -a /etc/snort/rules/local.rules # %22 is "
sudo service snort restart