require 'pp'
require 'optparse'
require 'date'
require 'logger'
require 'tempfile'
require 'cgi'
require 'tempfile'

require 'packer_templates/packer'
require 'packer_templates/script_base'

module PackerTemplates
	class BuildVsphereImport < ScriptBase

		def initialize(params)

			@cloudinit = params[:cloudinit]

			super(params)
		end

		def get_variables

			return {
				:ssh_username      => @ssh_user,
				:ssh_password      => @ssh_pass,
				:cm                => 'puppet',
			}
		end

		def cloudinit()

			vmdk = File.absolute_path("./cloudinit.vmdk")

			Dir.mktmpdir('cloudinit') do |dir|

				metadata = File.new("#{dir}/meta-data", "w+")
				metadata.write("instance-id: iid-local01; echo local-hostname: \"#{@name}\";")
				metadata.close

				userdata = File.new("#{dir}/user-data", "w+")
				userdata.write("#cloud-config\npassword: #{@ssh_pass}\nchpasswd: { expire: False }\nssh_pwauth: True\n")
				userdata.close

				img = Tempfile.new('seed_img')

				[
					"truncate --size 2M \"#{img.path}\"",
					"/sbin/mkfs.vfat -n cidata \"#{img.path}\"",
					"mcopy -oi \"#{img.path}\" #{userdata.path} ::",
					"mcopy -oi \"#{img.path}\" #{metadata.path} ::",
					"qemu-img convert -O vmdk \"#{img.path}\" \"#{vmdk}\"",
				].each do |command|
					@logger.info("Executing command: '#{command}'.")
					raise "Command failed: #{command}" if ! system(command)
				end
			end

			return {
				second_disk_path:    vmdk,
				second_disk_present: "TRUE",
			}
		end

		def build_vm
			@logger.info("Building '#{@name}' locally.")

			flags = [
#                               'debug',
				'force',
			]

			variables = get_variables
			variables.merge!(cloudinit()) if @cloudinit

			ret = PackerTemplates::Packer.build(@packer_template, 'vmware-iso', variables, flags)

			raise "Unable to build VM: #{$?}." if !ret
		end

		def vm_dir
			return File.dirname(@packer_template) + "/output-vmware-iso/"
		end

		def import_command
			vmx_path = vm_dir() + File.basename(@packer_template).gsub('json', 'vmx')

			vsphere_user = CGI.escape(@vsphere_user)

			command = [
				"ovftool",
				"--name=\"#{@name}\"",
				"--datastore=\"#{@vsphere_datastore}\"",
				"--network=\"#{@vsphere_network}\"",
				"\"#{vmx_path}\"",
				"\"vi://#{vsphere_user}:#{vsphere_pass}@#{@vsphere_host}/#{@vsphere_compute_resource}/Resources/#{@vsphere_pool}\"",
			].join(" ")

			return command
		end

		def import_vm
			@logger.info("Importing to vSphere")

			command = import_command()

			@logger.info("Executing command: '#{command}'.")

			ret = system(command)

			raise "Unable to import VM: #{$?}." if !ret
		end

		def go
			build_vm
			import_vm

			@logger.info("Finished successfully.")
		end
	end
end

