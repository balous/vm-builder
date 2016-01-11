#!/usr/bin/env ruby

require 'pp'
require 'optparse'
require 'logger'
require 'date'

require 'packer_templates/script_base'
require 'packer_templates/vsphere'
require 'packer_templates/packer'

module PackerTemplates
	class ProvisionVsphere < ScriptBase 

		attr_reader :vm_config, :base_template

		def initialize(params)

			@base_template = params[:base_template]
			@finalize_hook = params[:finalize_hook]
			super(params)
		end

		def create_server

			@logger.info("Listing templates")
			# get the latest template
			regexp = Regexp.new("#{@base_template}-\\d+$")
			templates = @vsphere.list_templates(regexp)

			template = templates.sort{|a, b| a.name <=> b.name}[-1]

			raise "Unable to find template '#{@base_template}]}'" if template.nil?

			@logger.info("Found template: #{template.name}")

			@logger.info("Creating instance #{@vm_name}")

			instance_params = {
				:name             => @vm_name,
				:resource_pool    => @vsphere_pool,
				:compute_resource => @vsphere_compute_resource,
				:datastore        => @vsphere_datastore,
			}

			# if you want to start on existing VM, uncomment and update this and comment some lines below
#			@vm = @vsphere.list_templates(/saio-2015-12-08-15-15-30/).sort{|a, b| a.name <=> b.name}[-1]

			@vm = @vsphere.create_instance(template, instance_params)

			reconfigure_vm()

			@logger.info("Starting instance #{@vm.name}")
			@vsphere.start_instance(@vm)

			@logger.info("Waiting for IP address...")
			@ip = @vsphere.get_vm_address(@vm)
			@logger.info("... #{@ip}")
		end

		def stop_server
			@logger.info("Stopping instance...")
			@vsphere.stop_instance(@vm)
			@logger.info("...stopped")
		end

		def provision_server
			@logger.info("Provisioning with packer")

			variables = {
				:ssh_address      => @ip,
				:server_name      => @name,
				:ssh_username     => @ssh_user,
				:ssh_password     => @ssh_pass,
				:vsphere_instance => @vm.name,
			}

			variables.merge!(@packer_vars) if not @packer_vars.nil?

			flags = [
				#	'debug',
			]

			ret = PackerTemplates::Packer.build(@packer_template, 'null', variables, flags, @packer_var_file)

			raise "Provisioning failed." if not ret
		end

		def reconfigure_vm
			@logger.info("Configuring virtual HW")

			#override network adapter's default with command line param value
			if (not @vsphere_network.nil?) and (not @vm_config[:networks].nil?)
				raise "Unable to set network for multiple adapters" if @vm_config[:networks].size != 1

				first = @vm_config[:networks].keys.first
				@vm_config[:networks][first] = @vsphere_network

			end

			@vsphere.reconfigure_vm(@vm, @vm_config)
		end

		def go
			@logger = Logger.new(STDOUT)

			connect_vsphere
			create_server
			provision_server
			stop_server
			@finalize_hook.call(@logger, @vm) if not @finalize_hook.nil?
		end
	end
end
