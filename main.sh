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
AI and Security Cloud Services: VPC & IDS project 

Authors: Sebastien BOIS - Maxime BOUET - Thibault RENOU - Yanis TAHRAT
Date: 30/10/2023

This script is used to mount automatically the architecture of the project.
It requires the AWS Access Key ID, AWS Secret Access Key, and the region of the service.
To retrieve these data, launch a sandbox session and start the lab.
The data will be printed in the tab 'Details'.
=========================================================================================

EOF

if [ $traffic_mirroring -eq 1 ]; then
    echo -e "The IDS will be installed using Traffic Mirroring.\n"
else
    echo -e "The IDS will be installed directly on the Web Server.\n"
fi


####################
## 1. INSTALL VPC ##
####################

# Run the script with variables
echo "Mounting VPC server..."
"$install_vpc_script -c $config_file"


##################################
## 2. INSTALL TRAFFIC MIRRORING ##
##################################

# Read variables from the VPC script
if [ -f $vpc_variables_file ]; then
    source $vpc_variables_file
else
    echo "Error: Configuration file $vpc_variables_file not found."
    exit 1
fi

# Run the script with variables
if [ $traffic_mirroring -eq 1 ]; then
    echo "Mounting IDS Server..."
    "$install_ids_script -c $config_file -v $vpc_variables_file"
fi