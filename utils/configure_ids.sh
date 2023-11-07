#!/bin/bash

# Retrieves command parameters
while getopts k:b: flag
do
	case "${flag}" in
		k) network_interface_ids_id=${OPTARG};;
	esac
done

sudo apt update -y
sudo apt upgrade -y
sudo apt install snort -y

sudo sed -i s/eth0/$network_interface_ids_id/g /etc/systemd/system/snort.service

echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"select"; sid:1000001;)' | sudo tee -a /etc/snort/rules/local.rules
echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"SELECT"; sid:1000002;)' | sudo tee -a /etc/snort/rules/local.rules
echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"%27"; sid:1000003;)' | sudo tee -a /etc/snort/rules/local.rules # %27 is '
echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"%22"; sid:1000004;)' | sudo tee -a /etc/snort/rules/local.rules # %22 is "
sudo service snort restart