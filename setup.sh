#!/bin/bash

config_file=cfg/config.ini

################################
## 1. READ CONFIGURATION FILE ##
################################

if [ -f $config_file ]; then
    source $config_file
else
    echo "Error: Configuration file $config_file not found."
    exit 1
fi


##############################
## 2. GIVE EXECUTION RIGHTS ##
##############################

chmod +x ./*.sh
chmod +x $scripts_folder/*.sh
echo "1) Execution rights have been given to all scripts"


################################
## 3. REMOVE EXISTING SSH KEY ##
################################

echo
read -p "2) Do you want to remove existing $keyname SSH key? [y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Removing SSH key..."
    if [ -f $ssh_folder$keyname ]; then
        rm $ssh_folder$keyname
        echo "$ssh_folder$keyname has been removed"
    else
        echo "$ssh_folder$keyname not found"
    fi

    if [ -f $ssh_folder$keyname.pub ]; then
        rm $ssh_folder$keyname.pub
        echo "$ssh_folder$keyname.pub has been removed"
    else
        echo "$ssh_folder$keyname.pub not found"
    fi
fi



########################################
## 4. REMOVE EXISTING AWS CREDENTIALS ##
########################################

echo
read -p "3) Do you want to remove existing AWS credentials? [y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Removing AWS credentials..."
    if [ -f $credentials_file ]; then
        rm $credentials_file
        echo "$credentials_file have been removed"
    else
        echo "$credentials_file not found"
    fi
fi


###################################
## 5. SET UP NEW AWS CREDENTIALS ##
###################################

echo
read -p "4) Do you want to set up new AWS credentials? [y/n] " -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then

    echo "Enter your AWS credentials from the sandbox session :"
    
    # Read lines until an empty line is encountered
    credentials=""
    while true; do
        read -r line
        if [[ -z $line ]]; then
            break
        fi
        credentials="$credentials$line"$'\n'
    done
    
    # Save the credentials to the ~/.aws/credentials file
    echo "$credentials" > $credentials_file
    
    echo "Credentials have been set in $credentials_file"
fi