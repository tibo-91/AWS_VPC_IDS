#!/bin/bash

# Install and configure Snort
sudo apt update -y
sudo apt update -y
sudo apt install snort -y

echo 'alert udp any any -> $HOME_NET 4789 (msg:"SQL Injection attempt"; content:"select"; sid:1000001;)' | sudo tee -a /etc/snort/rules/local.rules
echo 'alert udp any any -> $HOME_NET 4789 (msg:"SQL Injection attempt"; content:"SELECT"; sid:1000002;)' | sudo tee -a /etc/snort/rules/local.rules
echo 'alert udp any any -> $HOME_NET 4789 (msg:"SQL Injection attempt"; content:"%27"; sid:1000003;)' | sudo tee -a /etc/snort/rules/local.rules # %27 is '
echo 'alert udp any any -> $HOME_NET 4789 (msg:"SQL Injection attempt"; content:"%22"; sid:1000004;)' | sudo tee -a /etc/snort/rules/local.rules # %22 is "

sudo service snort restart