#!/bin/bash

# Install Snort
sudo apt update -y
sudo apt upgrade -y
sudo apt install snort -y

# Configure rules to detect SQL Injection
echo 'alert udp any any -> $HOME_NET 4789 (msg:"SQL Injection attempt: select detected"; content:"select"; sid:1000001;)' | sudo tee -a /etc/snort/rules/local.rules
echo 'alert udp any any -> $HOME_NET 4789 (msg:"SQL Injection attempt: SELECT detected"; content:"SELECT"; sid:1000002;)' | sudo tee -a /etc/snort/rules/local.rules
echo 'alert udp any any -> $HOME_NET 4789 (msg:"SQL Injection attempt: %27 detected"; content:"%27"; sid:1000003;)' | sudo tee -a /etc/snort/rules/local.rules # %27 is '  
echo 'alert udp any any -> $HOME_NET 4789 (msg:"SQL Injection attempt: %22 detected"; content:"%22"; sid:1000004;)' | sudo tee -a /etc/snort/rules/local.rules # %22 is "

sudo service snort restart