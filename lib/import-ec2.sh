#!/bin/bash -e

set -o pipefail 

packer_template=$1
template_name=$2
os_type=$3

region=eu-west-1
bucket=samepage-it-vms

template_dir=$(dirname "${packer_template}")

rm -f disk.vmdk

echo "Converting VM to importable format"
vmware-vdiskmanager -r "$template_dir/output-vmware-iso/disk.vmdk" -t 5 disk.vmdk

#exit

echo "Importing image as a temporary instance"
output=$(ec2-import-instance --region "$region" -o "$AWS_ACCESS_KEY" -w "$AWS_SECRET_KEY" -b "$bucket" -f vmdk -p "$os_type" -t t2.micro -a x86_64 disk.vmdk)

#rm disk.vmdk

task=$(echo $output | sed -e 's/.*import-/import-/' -e 's/\s.*//')
folder=$(echo $output | sed -e "s/.*$bucket\///" -e 's/\/.*//')
instance=$(echo $output | sed -e 's/.*InstanceID\s*i-/i-/' -e 's/\s.*//')

while ec2-describe-conversion-tasks --region "$region" | grep active | grep $task ; do
	sleep 10
done

echo "Clearing imported image from S3 bucket"
s3cmd --access_key "$AWS_ACCESS_KEY" --secret_key "$AWS_SECRET_KEY" -r del "s3://$bucket/$folder"

echo "Searching for previous version of this AMI"
previous=$(ec2-describe-images --region "$region" | grep "${template_name}"| sed -e 's/.*IMAGE\s*//' -e 's/\s.*//')
if [ -n "$previous" ] ;  then

	echo "Deleting previous version of this AMI"
	snapshot=$(ec2-describe-snapshots --region "$region" | grep "$previous" | sed -e 's/SNAPSHOT\s*//' -e 's/\s.*//')

	ec2-deregister --region "$region" "$previous"
	ec2-delete-snapshot --region "$region" "$snapshot"
fi

echo "Converting temporary instance to AMI"
ami=$(ec2-create-image --region "$region" --block-device-mapping /dev/sda1=:2:true:gp2 -n "${template_name}" "$instance" | sed 's/.*\s//')

while ec2-describe-images --region "$region" | grep "$ami" | grep pending ; do
	sleep 10
done

echo "Deleting temporary instance"
ec2-terminate-instances --region "$region" "$instance"
