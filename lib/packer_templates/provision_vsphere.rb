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
			@vm_config     = params[:vm_config]
			super(params)
		end

		def connect
			@logger.info("Connecting to #{@vsphere_host}")

			@vsphere = PackerTemplates::Vsphere.new(@vsphere_host, @vsphere_user, @vsphere_pass)
		end

		def create_server 

			@logger.info("Listing templates")
			# get the latest template
			regexp = Regexp.new("#{@base_template}-\\d\\d\\d\\d-\\d\\d-\\d\\d-\\d\\d-\\d\\d-\\d\\d")
			templates = @vsphere.list_templates(regexp)

			template = templates.sort{|a, b| a.name <=> b.name}[-1]

			raise "Unable to find template '#{@base_template}]}'" if template.nil?

			@logger.info("Found template: #{template.name}")

			@logger.info("Creating instance #{@name}")

			instance_params = {
				:name             => name,
				:resource_pool    => @vsphere_pool,
				:compute_resource => @vsphere_compute_resource,
				:datastore        => @vsphere_datastore,
			}

			@vm = @vsphere.create_instance(template, instance_params)

			@logger.info("Configuring virtual HW")
			@vsphere.reconfigure_vm(@vm, @vm_config)

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
				:server_name      => @name.gsub(/-\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d/, ""),
				:ssh_username     => @ssh_user,
				:ssh_password     => @ssh_pass,
				:vsphere_instance => @vm.name,
			}

			flags = [
				#	'debug',
			]

			ret = PackerTemplates::Packer.build(@packer_template, 'null', variables, flags)

			raise "Provisioning failed." if not ret
		end

		def go
			@logger = Logger.new(STDOUT)

			connect
			create_server
			provision_server
			stop_server
		end
	end
end
