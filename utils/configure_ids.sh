#!/bin/bash
network_interface_id=eni-0a0a0a0a0a0a0a0a0 # random ID for testing purpose
echo "Configuring Traffic Mirroring..."

sudo apt update -y
sudo apt upgrade -y
sudo apt install snort -y

snort -A console -i $network_interface_id -u snort -c /etc/snort/snort.conf

echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"select"; sid:1000001;)' | sudo tee -a /etc/snort/rules/local.rules
echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"SELECT"; sid:1000002;)' | sudo tee -a /etc/snort/rules/local.rules
echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"%27"; sid:1000003;)' | sudo tee -a /etc/snort/rules/local.rules # %27 is '
echo 'alert tcp any any -> $HOME_NET 80 (msg:"SQL Injection attempt"; content:"%22"; sid:1000004;)' | sudo tee -a /etc/snort/rules/local.rules # %22 is "
sudo service snort restart