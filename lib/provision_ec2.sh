#!/bin/bash

source_name=$1      # ami to take
result_name=$2      # ami to produce
host_name=$3        # what to install inside
packer_template=$4

template_dir=$(dirname "${packer_template}")
template_file=$(basename "${packer_template}")

region='eu-west-1'

echo "Searching for $source_name AMI"
source=$(ec2-describe-images --region "$region" | grep "$source_name" | sed -e 's/.*IMAGE\s//' -e 's/\s.*//')
if [ -z "$source" ] ; then
	echo "Source AMI doesn't exist"
	exit -1
fi

echo "Searching for previous version of the AMI"
image=$(ec2-describe-images --region "$region" | grep "$result_name\s" | sed -e 's/.*IMAGE\s*//' -e 's/\s.*//')

if [ -n "$image" ] ;  then

	echo "Deleting previous version of the AMI"
	snapshot=$(ec2-describe-snapshots --region "$region" | grep "$image" | sed -e 's/SNAPSHOT\s*//' -e 's/\s.*//')

	ec2-deregister --region "$region" "$image"
	ec2-delete-snapshot --region "$region" "$snapshot"
fi

pushd "$template_dir"

echo "Building the AMI"
packer build -var source_ami="$source" -var region="$region" -var server_name="$host_name" -var ami_name="$result_name" --only amazon-ebs "$template_file"

popd
