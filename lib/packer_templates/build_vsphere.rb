require 'pp'
require 'optparse'
require 'date'
require 'logger'
require 'tempfile'

require 'packer_templates/packer'
require 'packer_templates/vsphere'

module PackerTemplates
	class BuildVsphere

		attr_reader :vsphere_host, :vsphere_user, :vsphere_pass, :vsphere_network,
			:vsphere_datastore, :vsphere_pool, :packer_template, :name,
			:ssh_user, :ssh_pass

		def initialize(params)
			suffix = "-" + DateTime.now.strftime("%Y-%m-%d-%H-%M-%S")

			@name            = params[:name] + suffix
			@packer_template = params[:packer_template]
			@ssh_user        = params[:ssh_user]
			@ssh_pass        = params[:ssh_pass]

			@vsphere_host      = params[:vsphere_host]
			@vsphere_network   = params[:vsphere_network]
			@vsphere_datastore = params[:vsphere_datastore]
			@vsphere_pool      = params[:vsphere_pool]

			parse_cli(params[:cli_opts])
			validate_params()
		end

		def parse_cli(cli_opts)
			@vsphere_user      = ENV["vsphere_user"]
			@vsphere_pass      = ENV["vsphere_password"]

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
			end.parse!(cli_opts)
		end

		def validate_params()
			raise "Datastore must be specified." if @vsphere_datastore.nil?
			raise "Virtual network must be specified." if @vsphere_network.nil?
			raise "vSphere host must be specified." if @vsphere_host.nil?
		end

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
				pool: @vsphere_pool,
			)
		end

		def go
			@logger = Logger.new(STDOUT)
			@logger.info("Building '#{@name}' on hypervisor '#{vsphere_host}'.")

			build_template
			register_template

			@logger.info("Finished successfully.")
		end
	end
end

