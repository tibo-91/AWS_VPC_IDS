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

# Import configuration file into the script
read -r -d '' replacements <<EOF
10s|.*|config_file=$config_file|
11s|.*|source $config_file|
EOF

sed -i "$replacements" "$install_vpc_script"

# Run the script
echo "Mounting VPC server..."
"$install_vpc_script"

# Remove configuration file from the script
sed -i '10s|.*||; 11s|.*||' "$install_vpc_script"



##################################
## 2. INSTALL TRAFFIC MIRRORING ##
##################################

if [ $traffic_mirroring -eq 1 ]; then

    # Verify that the variables from the VPC script are available
    if [ ! -f "$vpc_variables_file" ]; then 
        echo "Error: Configuration file $vpc_variables_file not found."
        exit 1
    fi

    # Import configuration file and variables into the script
    read -r -d '' replacements <<EOF
    10s|.*|config_file=$config_file|
    11s|.*|source $config_file|
    12s|.*|vpc_variables_file=$vpc_variables_file|
    13s|.*|source $vpc_variables_file|
EOF

    sed -i "$replacements" "$install_ids_script"

    # Run the script
    echo "Mounting IDS Server..."
    "$install_ids_script"

    # Remove configuration file from the script
    sed -i '10s|.*||; 11s|.*||; 12s|.*||; 13s|.*||' "$install_ids_script"
fi


echo -e "\n\nDone"