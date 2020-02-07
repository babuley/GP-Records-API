#!/bin/bash
# This script is meant to be run in the User Data of each EC2 Instance while it's booting. The script uses the
# run-consul script to configure and start Consul in client mode. Note that this script assumes it's running in an AMI
# built from the Packer template in examples/consul-ami/consul.json.

set -e

function has_yum {
  [ -n "$(command -v yum)" ]
}

function has_apt_get {
  [ -n "$(command -v apt-get)" ]
}

function install_dependencies {
  echo "Installing dependencies"

  if $(has_apt_get); then
    sudo apt-get update -y
    sudo apt-get install -y awscli curl unzip jq
  elif $(has_yum); then
    sudo yum update -y
    sudo yum install -y aws-cli curl unzip jq git wget nano
  else
    echo "Could not find apt-get or yum. Cannot install dependencies on this OS."
    exit 1
  fi
}




# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1


# You could add commands to boot your other apps here

install_dependencies


if [ ! "$(docker ps -q -f name=${container_name})" ]; then
    if [ ! "$(docker ps -aq -f status=exited -f name=${container_name})" ]; then
        echo "Router install..."
		
        #Login to docker repo  
        awsregion="${aws_region}"  
        docker_pwd_resolver="aws secretsmanager get-secret-value --region $awsregion --secret-id docker_repo_password"
        data=$(eval $docker_pwd_resolver)
        docker_repo_password_secret=$(echo $data | jq -r '.SecretString' | jq -r '.docker_repo_password')        
		
        echo "~~~AWS SECRET MANAGER~~~"        
        docker login -u ${docker_repo_user} -p $docker_repo_password_secret ${docker_repo}

        docker run -d -p 8080:8080 ${container_name}:latest
    fi
fi
