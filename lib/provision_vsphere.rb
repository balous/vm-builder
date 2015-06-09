#!/usr/bin/env ruby

require 'pp'
require 'optparse'
require 'logger'

require 'packer_templates/vsphere'
require 'packer_templates/packer'

class ProvisionVsphere
	def parse_options
		options = {}
		OptionParser.new do |opts|
			opts.banner = "Usage: provision_vsphere.rb [options]"

			opts.on("--server_name=name", "Name of server to create") do |val|
				options[:server_name] = val
			end

			opts.on("--vm_template=name", "Name of template to instantiate") do |val|
				options[:vm_template] = val
			end

			opts.on("--packer_template=name", "Path to packer template to use") do |val|
				options[:packer_template] = val
			end

			opts.on("--host=address", "Virtual center host address") do |val|
				options[:host] = val
			end

			opts.on("--user=name", "Virtual center login name") do |val|
				options[:user] = val
			end

			opts.on("--pass=password", "Virtual center login password") do |val|
				options[:pass] = val
			end

			opts.on("--=password", "Virtual center login password") do |val|
				options[:pass] = val
			end

			opts.on('-h', '--help', "Print usage") do
				puts opts
			end
		end.parse!

		[:server_name, :vm_template, :packer_template, :host, :user, :pass].each do |option|
			raise "Option '#{option}' must be specified!" if options[option].nil?
		end

		@options = options
	end

	def connect
		@logger.info("Connecting to #{@options[:host]}")

		@vsphere = PackerTemplates::Vsphere.new(@options[:host], @options[:user], @options[:pass])
	end

	def create_server 

		@logger.info("Listing templates")
		# get the latest template
		regexp = Regexp.new("#{@options[:vm_template]}-\\d\\d\\d\\d-\\d\\d-\\d\\d \\d\\d-\\d\\d-\\d\\d")
		templates = @vsphere.list_templates(regexp)
		template = templates.sort{|a, b| a.name <=> b.name}[-1]

		raise "Unable to find template '#{@options[:vm_template]}'" if template.nil?

		@logger.info("Found template: #{template.name}")

		@logger.info("Creating instance #{@options[:server_name]}")

		instance_params = {
			:name => @options[:server_name],
		}

		@vm = @vsphere.create_instance(template, instance_params)

#		@vm = @vsphere.list_templates(Regexp.new("^#{@options[:server_name]}$"))[0]

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
			:ssh_address => @ip,
			:server_name  => @options[:server_name],
		}

		flags = [
			#	'debug',
		]

		ret = PackerTemplates::Packer.build(@options[:packer_template], 'null', variables, flags)

		raise "Provisioning failed." if not ret
	end

	def go
		@logger = Logger.new(STDOUT)

		parse_options
		connect
		create_server
		provision_server
		stop_server
	end
end

pv = ProvisionVsphere.new
pv.go

