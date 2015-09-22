require 'pp'
require 'optparse'
require 'date'
require 'logger'
require 'tempfile'

require 'packer_templates/packer'
require 'packer_templates/vsphere'
require 'packer_templates/script_base'

module PackerTemplates
	class BuildVsphere < ScriptBase

		def get_variables

			return {
				:vm_name           => @name,
				:output_directory  => @name,
				:ssh_username      => @ssh_user,
				:ssh_password      => @ssh_pass,
				:remote_type       => 'esx5',
				:remote_host       => @vsphere_host,
				:remote_username   => @vsphere_user,
				:remote_password   => @vsphere_pass,
				:vm_network        => @vsphere_network,
				:remote_datastore  => @vsphere_datastore,
				:cm		   => 'puppet',
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

			@vsphere = PackerTemplates::Vsphere.new(@vsphere_host, @vsphere_user, @vsphere_pass)
			@vsphere.register_instance(
				name: @name,
				path: path,
				datastore: @vsphere_datastore,
			)
		end

		def go
			@logger.info("Building '#{@name}' on hypervisor '#{vsphere_host}'.")

			build_template
			register_template

			@logger.info("Finished successfully.")
		end
	end
end

