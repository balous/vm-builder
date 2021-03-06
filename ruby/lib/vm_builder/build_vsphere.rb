require 'pp'
require 'optparse'
require 'date'
require 'logger'
require 'tempfile'

require 'vm_builder/packer'
require 'vm_builder/vsphere'
require 'vm_builder/script_base'
require 'vm_builder/ovftool'

module VmBuilder
	class BuildVsphere < ScriptBase

		def initialize(params)

			@vsphere_host_thumbprint = params[:vsphere_host_thumbprint]
			super(params)
		end

		def validate_params()
			raise "Virtual network must be specified." if @vsphere_network.nil?
			super()
		end

		def get_variables

			vars = {
				:vm_name                => @vm_name,
				:output_directory       => @vm_name,
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

			vars.merge!(@packer_vars) if not @packer_vars.nil?

			return vars
		end

		def build_template
			@logger.info("Building VM #{@vm_name}")

			flags = [
#				'debug',
				'force',
			]

			variables = get_variables

			ret = VmBuilder::Packer.build(@packer_template, 'vmware-iso', variables, flags, @packer_var_file)
		end

		def register_template
			path = "#{@vm_name}/#{@vm_name}.vmx"

			@logger.info("Registering vmx file '#{path}'.")

			@vm = @vsphere.register_instance(
				name: @vm_name,
				path: path,
				datastore: @vsphere_datastore,
			)
		end

		def reconfigure_vm
			@logger.info("Configuring virtual HW")

			if @vm_config != nil
				@vsphere.reconfigure_vm(@vm, @vm_config)
			end
		end

		def go
			@logger.info("Building '#{@vm_name}' on hypervisor '#{vsphere_host}'.")

			connect_vsphere
			build_template
			register_template
			reconfigure_vm

			@logger.info("Finished successfully.")
		end

		def export_vm (dest)

			@logger.info("Exporting vm '#{@vm_name}' to OVF '#{dest}'.")
			return VmBuilder::OvfTool.export(
				dest:            dest,
				name:            @vm_name,
				host:            @vsphere_host,
				user:            @vsphere_user,
				host_thumbprint: @vsphere_host_thumbprint,
				password:        @vsphere_pass,
				folder:          nil,
				datastore:       nil,
			)
		end

		def delete_vm
			@logger.info("Deleting vm '#{@vm_name}'.")
			@vsphere.delete_instance(@vm)
		end
	end
end

