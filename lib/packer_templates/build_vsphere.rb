require 'pp'
require 'optparse'
require 'date'
require 'logger'
require 'tempfile'

require 'packer_templates/packer'
require 'packer_templates/vsphere'
require 'packer_templates/script_base'
require 'packer_templates/ovftool'

module PackerTemplates
	class BuildVsphere < ScriptBase

		def initialize(params)

			@vsphere_host_thumbprint = params[:vsphere_host_thumbprint]
			super(params)
		end

		def get_variables

			return {
				:vm_name                => @name,
				:output_directory       => @name,
				:ssh_username           => @ssh_user,
				:ssh_password           => @ssh_pass,
				:remote_type            => 'esx5',
				:remote_host            => @vsphere_host,
				:remote_username        => @vsphere_user,
				:remote_password        => @vsphere_pass,
				:vm_network             => @vsphere_network,
				:remote_datastore       => @vsphere_datastore,
				:cm		        => 'puppet',
			}
		end

		def build_template
			@logger.info("Building VM #{@name}")

			flags = [
#				'debug',
				'force',
			]

			variables = get_variables

			ret = PackerTemplates::Packer.build(@packer_template, 'vmware-iso', variables, flags)
		end

		def register_template
			path = "#{@name}/#{@name}.vmx"

			@logger.info("Registering vmx file '#{path}'.")

			@vm = @vsphere.register_instance(
				name: @name,
				path: path,
				datastore: @vsphere_datastore,
			)
		end

		def go
			@logger.info("Building '#{@name}' on hypervisor '#{vsphere_host}'.")

			connect_vsphere
			build_template
			register_template

			@logger.info("Finished successfully.")
		end

		def export_vm (dest)

			@logger.info("Exporting vm '#{@name}' to OVF '#{dest}'.")
			return PackerTemplates::OvfTool.export(
				dest:            dest,
				name:            @name,
				host:            @vsphere_host,
				user:            @vsphere_user,
				host_thumbprint: @vsphere_host_thumbprint,
				password:        @vsphere_pass,
				folder:          nil,
				datastore:       nil,
			)
		end

		def delete_vm
			@logger.info("Deleting vm '#{@name}'.")
			@vsphere.delete_instance(@vm)
		end
	end
end

