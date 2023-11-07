#!/bin/bash

##############################################################
########################### WARNING ########################## 
##                                                          ##
## Keep lines 10-13 empty                                   ##
## The main script will write some variables on these lines ##
## If the lines are not empty, they will be overwritten     ##
##############################################################




#############################
## 1. IDS SERVICE MOUNTING ##
#############################

# Security Group
ids_secgrp_id=`aws ec2 create-security-group \
	--description "Security Group for the Snort IDS Server" \
	--group-name ids-server \
	--vpc-id $vpc_id \
	--tag-specification ResourceType=security-group,Tags="[{Key=Name,Value=IDS_Server_SecurityGroup}]" \
	--output text \
	--query "GroupId"`
echo "- IDS Server security group $ids_secgrp_id has been created"

# Inbound rule
aws ec2 authorize-security-group-ingress \
	--group-id $ids_secgrp_id \
	--protocol tcp \
	--port $ssh_port \
	--cidr $ids_in_rule_cidr > /dev/null
echo "- $ids_secgrp_id: Authorizing incoming TCP request on port $ssh_port for $ids_in_rule_cidr"

# Launch IDS Server
ids_server_id=`aws ec2 run-instances \
	--image-id $ids_image_id \
	--instance-type $ids_instance_type \
	--security-group-id $ids_secgrp_id \
	--subnet-id $private_id \
	--key-name $keyname \
	--output text \
	--query "Instances[0].InstanceId"`
echo "- IDS Server has been launched with InstanceID $ids_server_id"


# Update and install packages
echo -e "\nWaiting for IDS Server to be ready..."
while true; do

	ids_status=`aws ec2 describe-instance-status \
		--instance-ids $ids_server_id \
		--query 'InstanceStatuses[0].InstanceState.Name' \
		--output text`


    echo "- Server's current state: IDS=$ids_status ($ids_server_id)"


	if [[ "$ids_status" == "running" ]]; then
		sleep 5
		echo -e "\nIDS Server is ready to be configured!"
		sleep 5

		ids_ipv4=`aws ec2 describe-instances \
			--instance-ids $ids_server_id \
			--query "Reservations[0].Instances[0].PrivateIpAddress" | grep -Eo "[0-9.]+"`
			
		ssh -i ~/.ssh/$keyname \
		    -t ubuntu@$ids_ipv4 \
            "ssh -i ~/.ssh/$keyname ubuntu@$ids_ipv4 -t 'wget $repository_path/utils/configure_ids.sh'; \
            sudo chmod +x ./configure_ids.sh; \
            sudo bash ./configure_ids.sh"
		break
	fi
    sleep 10
done


cat <<EOF


=========================================================================================

The IDS has been configured. 

=========================================================================================

EOF