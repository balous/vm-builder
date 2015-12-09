require 'pp'
require 'optparse'
require 'date'
require 'logger'
require 'tempfile'
require 'packer_templates/vsphere'

module PackerTemplates
	class ScriptBase

		attr_reader :vsphere_host, :vsphere_user, :vsphere_pass, :vsphere_network,
			:vsphere_datastore, :vsphere_pool, :vsphere_compute_resource, :packer_template, :packer_vars, :name, :vm_name,
			:ssh_user, :ssh_pass

		def initialize(params)

			@name            = params[:name]

			@packer_template = params[:packer_template]
			@packer_vars     = params[:packer_vars]

			@ssh_user        = params[:ssh_user]
			@ssh_pass        = params[:ssh_pass]

			@vsphere_host             = params[:vsphere_host]
			@vsphere_network          = params[:vsphere_network]
			@vsphere_datastore        = params[:vsphere_datastore]
			@vsphere_pool             = params[:vsphere_pool]
			@vsphere_compute_resource = params[:vsphere_compute_resource]

			parse_cli(params[:cli_opts])
			validate_params()

			@vm_name = @name + "-" + @name_suffix;

			STDOUT.sync = true
			STDERR.sync = true

			@logger = Logger.new(STDOUT)
		end

		def parse_cli(cli_opts)
			@vsphere_user      = ENV["vsphere_user"]
			@vsphere_pass      = ENV["vsphere_password"]

			@name_suffix = DateTime.now.strftime("%Y-%m-%d-%H-%M-%S")

			OptionParser.new do |opts|
				opts.banner = "Usage: #{$PROGRAM_NAME} [opts]"

				opts.on("--vsphere-host=name", "ESX host / vCenter to build on") do |val|
					@vsphere_host = val
				end

				opts.on("--vsphere-datastore=name", "Datastore to place the template on") do |val|
					@vsphere_datastore = val
				end

				opts.on("--vsphere-network=name", "Network name to attach the template to") do |val|
					@vsphere_network = val
				end

				opts.on("--vsphere-user=name", "vSphere connection username") do |val|
					@vsphere_user = val
				end

				opts.on("--vsphere-password=password", "vSphere connection password") do |val|
					@vsphere_pass = val
				end

				opts.on("--vm-suffix=password", "Custom VM name suffix") do |val|
					@name_suffix= val
				end
			end.parse!(cli_opts)
		end

		def connect_vsphere
			@logger.info("Connecting to #{@vsphere_host}")

			@vsphere = PackerTemplates::Vsphere.new(@vsphere_host, @vsphere_user, @vsphere_pass)
		end

		def validate_params()
			raise "Datastore must be specified." if @vsphere_datastore.nil?
			raise "vSphere host must be specified." if @vsphere_host.nil?
		end

		def go
			raise "Not implemented."
		end
	end
end

