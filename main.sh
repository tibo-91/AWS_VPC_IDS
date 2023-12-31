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
AI and Security Cloud Services
AWS project: VPC & IDS deployment 

Authors: Sebastien BOIS - Maxime BOUET - Thibault RENOU - Yanis TAHRAT
Date: 30/10/2023

This script is used to mount automatically the architecture of the project.
It requires the AWS Access Key ID, AWS Secret Access Key, and the region of the service.
To retrieve these data, launch a sandbox session and start the lab.
The data will be printed in the tab 'Details'.
=========================================================================================

EOF

# Check Traffic Mirroring parameter
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
"$scripts_folder$install_vpc_script" -c "$config_file"


# Read variables from the VPC script
if [ -f $variables_file ]; then
    source $variables_file
else
    echo "Error: Configuration file $variables_file not found."
    exit 1
fi

# End of the script (traffic mirroring disabled)
if [ $traffic_mirroring -eq 0 ]; then
    cat <<EOF


=========================================================================================

The servers has been configured. 

1) To access to the Web Server, go to the following URL: 
http://$web_ipv4/sqli/

2) To display Snort logs of the Web Server, run the following command:
ssh -i ~/.ssh/$keyname -t ubuntu@$web_ipv4 "tail -f /var/log/snort/snort.alert.fast"

=========================================================================================
EOF
fi


##################################
## 2. INSTALL TRAFFIC MIRRORING ##
##################################

# Run the script with variables
if [ $traffic_mirroring -eq 1 ]; then
    echo -e "\nMounting IDS Server..."
    "$scripts_folder$install_ids_script" -c "$config_file" -v "$variables_file"

    # Read variables from the IDS script
    source $variables_file

    # End of the script (traffic mirroring enabled)
    cat <<EOF


=========================================================================================================================================================================

The servers has been configured. 

1) To access to the Web Server, go to the following URL: 
http://$web_ipv4/sqli/

2) To display Snort logs of the IDS, run the following command:
ssh -i ~/.ssh/$keyname -t ubuntu@$web_ipv4 "ssh -i ~/.ssh/$keyname -t ubuntu@$ids_ipv4 'tail -f /var/log/snort/snort.alert.fast'"

=========================================================================================================================================================================
EOF
fi