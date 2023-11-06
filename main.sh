#!/bin/bash

config_file=cfg/config.ini

# Read configuration file
if [ -f $config_file ]; then
    source $config_file
else
    echo "Error: Configuration file $config_file not found."
    exit 1
fi

cat <<EOF
=========================================================================================
VPC & IDS Lab

Authors: Sebastien BOIS - Maxime BOUET - Thibault RENOU - Yanis TAHRAT
Date: 30/10/2023

This script is used to mount automatically the architecture of the project.
It requires the AWS Access Key ID, AWS Secret Access Key, and the region of the service.
To retrieve these data, launch a sandbox session and start the lab.
The data will be printed in the tab 'Details'.
=========================================================================================


EOF

if [ $traffic_mirroring -ne 1 ]; then
    echo -e "This script will install the IDS on the Web Server.\n"
else
    echo -e "This script will install the IDS using Traffic Mirroring.\n"
fi


## 1. Install VPC

(
    sed -i "2s|^|config_file=\"$config_file\"|" ./utils/install_vpc.sh
    sed -i '3s|^|source $config_file\n|' ./utils/install_vpc.sh

    ./utils/install_vpc.sh
)
sed -i "2d" ./utils/install_vpc.sh
sed -i "3d" ./utils/install_vpc.sh