#!/bin/bash -ex

set -o pipefail 

packer_template=$1
vm_name=$2

template_dir=$(dirname "${packer_template}")
template_file=$(basename "${packer_template}")

{ echo instance-id: iid-local01; echo local-hostname: "${vm_name}"; } > meta-data
printf "#cloud-config\npassword: zabibobra\nchpasswd: { expire: False }\nssh_pwauth: True\n" > user-data

seed_img=$(realpath ./seed.img)
seed_vmdk=$(realpath ./seed.vmdk)

truncate --size 2M "$seed_img"
/sbin/mkfs.vfat -n cidata "$seed_img"
mcopy -oi "${seed_img}" user-data meta-data ::
qemu-img convert -O vmdk "$seed_img" "$seed_vmdk"

pushd "$template_dir"

packer build --force --only=vmware-iso --var "second_disk_path=${seed_vmdk}" --var "second_disk_present=TRUE" "${template_file}"

popd

