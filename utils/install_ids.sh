#!/bin/bash

# Retrieves command parameters
while getopts c:v: flag
do
	case "${flag}" in
		c) config_file=${OPTARG};;
		v) variables_file=${OPTARG};;
	esac
done

# Import variables into the script
source $config_file
source $variables_file

##########################
## IDS SERVICE MOUNTING ##
##########################

# Security Group
ids_secgrp_id=`aws ec2 create-security-group \
	--description "Security Group for the Snort IDS Server" \
	--group-name ids-server \
	--vpc-id $vpc_id \
	--tag-specification ResourceType=security-group,Tags="[{Key=Name,Value=IDS_Server_SecurityGroup}]" \
	--output text \
	--query "GroupId"`
echo "- IDS Server security group $ids_secgrp_id has been created"

# Inbound rules
aws ec2 authorize-security-group-ingress \
	--group-id $ids_secgrp_id \
	--protocol tcp \
	--port $ssh_port \
	--cidr $vpc_cidr > /dev/null

aws ec2 authorize-security-group-ingress \
	--group-id $ids_secgrp_id \
	--protocol udp \
	--port $snort_port \ 
	--cidr $vpc_cidr > /dev/null

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

	# When the server is running, configure it
	if [[ "$ids_status" == "running" ]]; then
		sleep 5
		echo -e "\nIDS Server is ready to be configured!"
		sleep 5

		ids_ipv4=`aws ec2 describe-instances \
			--instance-ids $ids_server_id \
			--query "Reservations[0].Instances[0].PrivateIpAddress" | grep -Eo "[0-9.]+"`

		echo "- IDS Server IP is: $ids_ipv4"

		#######################
        ## Traffic mirroring ##
		#######################

        echo -e "\nCreating Traffic mirroring..."

		# Network interfaces
        network_interface_ids_id=`aws ec2 describe-instances \
            --instance-ids $ids_server_id \
            --output text \
            --query "Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId"`
        echo "- The network interface ID targeted by the trafic mirroring is $network_interface_ids_id"

		network_interface_web_id=`aws ec2 describe-instances \
			--instance-ids $web_server_id \
			--output text \
			--query "Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId"`
		echo "- The network interface ID of the Web Server is $network_interface_web_id"

		# Mirrors target and filter
        mirror_target_id=`aws ec2 create-traffic-mirror-target \
			--network-interface-id $network_interface_ids_id \
			--output text \
			--query "TrafficMirrorTarget.TrafficMirrorTargetId"`
        echo "- The traffic mirror target $mirror_target_id has been created"

        mirror_filter_id=`aws ec2 create-traffic-mirror-filter \
			--output text \
			--query "TrafficMirrorFilter.TrafficMirrorFilterId"`
        echo "- The traffic mirror filter $mirror_filter_id has been created"

		# Filter rule
		aws ec2 create-traffic-mirror-filter-rule \
			--description "TCP Rule" \
			--traffic-direction ingress \
			--source-cidr-block $web_in_rule_cidr \
			--destination-cidr-block $public_subnet_cidr \
			--destination-port-range FromPort=80,ToPort=80 \
			--protocol 6 \
			--rule-number 1 \
			--rule-action accept \
			--traffic-mirror-filter-id $mirror_filter_id > /dev/null

		# Traffic mirror session
        traffic_mirror_session_id=`aws ec2 create-traffic-mirror-session \
            --network-interface-id $network_interface_web_id \
            --traffic-mirror-target-id $mirror_target_id \
            --traffic-mirror-filter-id $mirror_filter_id \
            --session-number 1 \
			--output text \
			--query "TrafficMirrorSession.TrafficMirrorSessionId"`
        echo -e "- The traffic mirror session $traffic_mirror_session_id has been created"
        
		######################
		## Installing Snort ##
		######################	

		echo -e "\n Installing Snort on IDS..."

		echo "- Sending configuration script to the Web Server $web_server_id"
		scp -i ~/.ssh/$keyname $scripts_folder$config_ids_script ubuntu@$web_ipv4:~/

		echo "- Executing commands using SSH protocol..."
		ssh -i ~/.ssh/$keyname -t ubuntu@$web_ipv4 "\
		    scp -i ~/.ssh/$keyname $config_ids_script ubuntu@$ids_ipv4:~/; \
		    ssh -i ~/.ssh/$keyname -t ubuntu@$ids_ipv4 '\
		        sudo chmod +x $config_ids_script; \
		        sudo bash $config_ids_script'"
		break
	fi
    sleep 10
done

# Add variables to the variables file
cat <<EOF >> $variables_file

ids_secgrp_id='$ids_secgrp_id'
ids_server_id='$ids_server_id'
ids_ipv4='$ids_ipv4'

network_interface_ids_id='$network_interface_ids_id'
network_interface_web_id='$network_interface_web_id'

mirror_target_id='$mirror_target_id'
mirror_filter_id='$mirror_filter_id'
traffic_mirror_session_id='$traffic_mirror_session_id'
EOF