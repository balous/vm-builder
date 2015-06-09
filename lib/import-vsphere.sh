#!/bin/bash -ex

set -o pipefail 

packer_template=$1
template_name=$2

template_dir=$(dirname "${packer_template}")
vmx_name=$(basename "${packer_template}" | sed s/\\.json//)
ovftool --name="$template_name-$(date +'%Y-%m-%d %H-%M-%S')" --network="THPVLAN342" "$template_dir/output-vmware-iso/${vmx_name}.vmx" "vi://$vsphere_user:$vsphere_password@vc55.kerio.local:443/THP%20Praha/host/DEV/Resources/team.sio/sio-at"