#!/bin/bash

server_name=$1
packer_template=$2
source_vmx=$3

source_vmx=$(realpath "$source_vmx")

template_dir=$(dirname "${packer_template}")
template_file=$(basename "${packer_template}")

pushd "$template_dir"
packer build --debug -var server_name="$server_name" --only vmware-vmx --var source_vmx="$source_vmx" --force "$template_file"
