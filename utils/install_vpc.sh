#!/bin/bash

##############################################################
########################### WARNING ########################## 
##                                                          ##
## Keep lines 10-11 empty                                   ##
## The main script will write some variables on these lines ##
## If the lines are not empty, they will be overwritten     ##
##############################################################


#############################
## 1. VPC SERVICE MOUNTING ##
#############################

# VPC 
vpc_id=`aws ec2 create-vpc \
    --cidr-block $vpc_cidr \
    --tag-specification ResourceType=vpc,Tags="[{Key=Name,Value=$name_tag}]" \
    --output text \
    --query "Vpc.VpcId"`

echo "- VPC $vpc_id has been created"


# Subnets
public_id=`aws ec2 create-subnet \
    --vpc-id $vpc_id \
    --cidr-block $public_subnet_cidr \
    --tag-specification ResourceType=subnet,Tags="[{Key=Name,Value=Public_Subnet}]" \
    --output text \
    --query "Subnet.SubnetId"`
echo "- Public Subnet $public_id has been created"

private_id=`aws ec2 create-subnet \
    --vpc-id $vpc_id \
    --cidr-block $private_subnet_cidr \
    --tag-specification ResourceType=subnet,Tags="[{Key=Name,Value=Private_Subnet}]" \
    --output text \
    --query "Subnet.SubnetId"`
echo "- Private Subnet $private_id has been created"


# Internet Gateway
ig_id=`aws ec2 create-internet-gateway \
    --tag-specification ResourceType=internet-gateway,Tags="[{Key=Name,Value=IG}]" \
    --output text \
    --query "InternetGateway.InternetGatewayId"` 
echo "- Internet Gateway $ig_id has been created"

aws ec2 attach-internet-gateway \
    --internet-gateway-id $ig_id \
    --vpc-id $vpc_id
echo "- Internet Gateway $ig_id has been attached to VPC $vpc_id"


# Elastic IP
elastic_id=`aws ec2 allocate-address \
    --output text \
    --query "AllocationId"`
echo "- Elastic IP $elastic_id created for the Public NAT Gateway"


# NAT Gateway
nat_id=`aws ec2 create-nat-gateway \
    --subnet-id $public_id \
    --allocation-id $elastic_id \
    --tag-specification ResourceType=natgateway,Tags="[{Key=Name,Value=Public_NAT}]" \
    --output text \
    --query "NatGateway.NatGatewayId"`
echo "- Public NAT Gateway $nat_id has been created"


# Route Tables
public_route_id=`aws ec2 create-route-table \
    --vpc-id $vpc_id \
    --tag-specification ResourceType=route-table,Tags="[{Key=Name,Value=Public_RouteTable}]" \
    --output text \
    --query "RouteTable.RouteTableId"`
echo "- Public Route Table $public_route_id has been created inside the VPC $vpc_id"

private_route_id=`aws ec2 create-route-table \
    --vpc-id $vpc_id \
    --tag-specification ResourceType=route-table,Tags="[{Key=Name,Value=Private_RouteTable}]" \
    --output text \
    --query "RouteTable.RouteTableId"`
echo "- Private Route Table $private_route_id has been created inside the VPC $vpc_id"


# Associate Route Tables to Subnets
aws ec2 associate-route-table \
    --route-table-id $public_route_id \
    --subnet-id $public_id > /dev/null
echo "- Public Route Table $public_route_id has been associated to Public Subnet $public_id"

aws ec2 associate-route-table \
    --route-table-id $private_route_id \
    --subnet-id $private_id > /dev/null
echo "- Private Route Table $private_route_id has been associated to Private Subnet $private_id"


# Create Routes
aws ec2 create-route \
    --route-table-id $public_route_id \
    --destination-cidr-block $route_destination_cidr \
    --gateway-id $ig_id > /dev/null
echo "- Public Route redirecting every request outside of the Public Subnet $public_id to the Internet Gateway $ig_id has been created"

aws ec2 create-route \
    --route-table-id $private_route_id \
    --destination-cidr-block $route_destination_cidr \
    --nat-gateway-id $nat_id > /dev/null
echo "- Private Route redirecting every request outside of the Private Subnet $private_id to the NAT Gateway $nat_id has been created"


# Security Groups
web_secgrp_id=`aws ec2 create-security-group \
    --description "Security Group for the Apache Web Server" \
    --group-name web_server \
    --vpc-id $vpc_id \
    --tag-specification ResourceType=security-group,Tags="[{Key=Name,Value=WebServer_SecurityGroup}]" \
    --output text \
    --query "GroupId"`
echo "- Web Server Security Group $web_secgrp_id has been created"

db_secgrp_id=`aws ec2 create-security-group \
    --description "Security Group for MariaDB Database Server" \
    --group-name db_server \
    --vpc-id $vpc_id \
    --tag-specification ResourceType=security-group,Tags="[{Key=Name,Value=DBServer_SecurityGroup}]" \
    --output text \
    --query "GroupId"`
echo "- DB Server security group $db_secgrp_id has been created"



###########################
## 2. SERVERS DEPLOYMENT ##
###########################

# Inbound rules
aws ec2 authorize-security-group-ingress \
    --group-id $web_secgrp_id \
    --protocol tcp \
    --port $web_port \
    --cidr $web_in_rule_cidr > /dev/null 
echo "- Web Server Security Group $web_secgrp_id: Authorizing incoming TCP request on port $web_port for $web_in_rule_cidr"

aws ec2 authorize-security-group-ingress \
    --group-id $web_secgrp_id \
    --protocol tcp \
    --port $ssh_port \
    --cidr $ssh_web_in_rule_cidr > /dev/null
echo "- Web Server Security Group $web_secgrp_id: Authorizing incoming TCP request on port $ssh_port for $ssh_web_in_rule_cidr"

aws ec2 authorize-security-group-ingress \
    --group-id $db_secgrp_id \
    --protocol tcp \
    --port $db_port \
    --cidr $db_in_rule_cidr > /dev/null
echo "- DB Server Security Group $db_secgrp_id: Authorizing incoming TCP request on port $db_port for $db_in_rule_cidr"

aws ec2 authorize-security-group-ingress \
    --group-id $db_secgrp_id \
    --protocol tcp \
    --port $ssh_port \
    --cidr $ssh_db_in_rule_cidr > /dev/null
echo "- DB Server Security Group $db_secgrp_id: Authorizing incoming TCP request on port $ssh_port for $ssh_db_in_rule_cidr"


# SSH Key-pair
echo 
ssh-keygen -t rsa -b 2048 -f ~/.ssh/$keyname
aws ec2 import-key-pair \
    --key-name $keyname \
    --public-key-material fileb://~/.ssh/$keyname.pub > /dev/null


# Launch servers 
echo
web_server_id=`aws ec2 run-instances \
    --image-id $web_image_id \
    --instance-type $web_instance_type \
    --security-group-id $web_secgrp_id \
    --subnet-id $public_id \
    --associate-public-ip-address \
    --key-name $keyname \
    --output text \
    --query "Instances[0].InstanceId"`
echo "- Web Server has been launched with InstanceID $web_server_id"

db_server_id=`aws ec2 run-instances \
    --image-id $db_image_id \
    --instance-type $db_instance_type \
    --security-group-id $db_secgrp_id \
    --subnet-id $private_id \
    --key-name $keyname \
    --output text \
    --query "Instances[0].InstanceId"`
echo "- DB Server has been launched with InstanceID $db_server_id"


# Update and install packages
echo -e "\nWaiting for the servers to be ready..."
while true; do

	web_status=`aws ec2 describe-instance-status \
        --instance-ids $web_server_id \
        --query 'InstanceStatuses[0].InstanceState.Name' \
        --output text`

	db_status=`aws ec2 describe-instance-status \
        --instance-ids $db_server_id \
        --query 'InstanceStatuses[0].InstanceState.Name' \
        --output text`

    echo "- Servers' current state: Web=$web_status ($web_server_id) | DB=$db_status ($db_server_id)"

    if [[ "$web_status" == "running" && "$db_status" == "running" ]]; then
        sleep 10
		echo -e "\nServers are ready to be configured!"
        sleep 5

		web_ipv4=`aws ec2 describe-instances \
            --instance-ids $web_server_id \
            --query "Reservations[0].Instances[0].PublicIpAddress" | grep -Eo "[0-9.]+"`

		db_ipv4=`aws ec2 describe-instances \
            --instance-ids $db_server_id \
            --query "Reservations[0].Instances[0].PrivateIpAddress" | grep -Eo "[0-9.]+"`
		
        echo "- Servers' IP are: Web=$web_ipv4; DB=$db_ipv4"

		echo "- Sending SSH public key to the Web Server $web_server_id"
        scp -i ~/.ssh/$keyname ~/.ssh/$keyname ubuntu@$web_ipv4:~/.ssh/
        echo "- Executing commands using SSH protocol..."
        ssh -i ~/.ssh/$keyname \
            -t ubuntu@$web_ipv4 <<EOF
                wget $repository_path/utils/install_webserver.sh
                sed -i '2s|.*|repository_path=${repository_path}|' ./install_webserver.sh
                sed -i '3s|.*|traffic_mirroring=${traffic_mirroring}|' ./install_webserver.sh
                sudo chmod +x ./install_webserver.sh
                sudo bash ./install_webserver.sh -k $keyname -b $db_ipv4
EOF
        break
	fi
	sleep 10
done


#######################
## 3.STORE VARIABLES ##
#######################

echo -e "\nStoring variables into $vpc_variables_file..."

if [ -f $vpc_variables_file ]; then
    rm $vpc_variables_file
fi

cat <<EOF > $vpc_variables_file
vpc_id='$vpc_id'

public_id='$public_id'
private_id='$private_id'

ig_id='$ig_id'
nat_id='$nat_id'
elastic_id='$elastic_id'

public_route_id='$public_route_id'
private_route_id='$private_route_id'

web_secgrp_id='$web_secgrp_id'
db_secgrp_id='$db_secgrp_id'

web_server_id='$web_server_id'
db_server_id='$db_server_id'

web_ipv4='$web_ipv4'
db_ipv4='$db_ipv4'
EOF