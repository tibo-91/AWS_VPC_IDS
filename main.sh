#!/bin/bash

config_file=cfg/config.ini

# Read configuration file
if [ -f $config_file ]; then
    source $config_file
    export $config_file
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



./utils/install_vpc.sh