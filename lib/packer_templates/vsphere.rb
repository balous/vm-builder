require 'pp'
require 'rbvmomi'

module PackerTemplates
	class Vsphere

		attr_reader :connection
		def initialize(hostname, username, password)

			@connection = RbVmomi::VIM.connect host: hostname, user: username, password: password, insecure: true
		end

		def list_folder(folder)
			result = []

			folder.children.each do |entity|
				type, junk = entity.to_s.split('(')

				case type
				when 'Folder'
					result.concat(list_folder(entity))
				when 'VirtualApp'
					# don't know how to list VMs in vApp
					next
				when 'Datacenter'
					result.concat(list_folder(entity.vmFolder))
				when 'VirtualMachine'
					result.push entity
				else
					raise "Unknown vSphere entity type: '#{type}'."
				end
			end

			return result
		end

		def list_templates(pattern = Regexp.new('.*'))

			result = []
			list_folder(@connection.rootFolder).each do |vm|
				if vm.name =~ pattern
					result.push vm
				end
			end
			return result
		end

		def create_instance(template, params)

			relocateSpec = RbVmomi::VIM.VirtualMachineRelocateSpec

			spec = RbVmomi::VIM.VirtualMachineCloneSpec(
				:location => relocateSpec,
				:powerOn  => false,
				:template => false
			)

			task = template.CloneVM_Task(
				:folder => template.parent,
				:name   => params[:name],
				:spec   => spec
			)

			return task.wait_for_completion
		end

		def start_instance(vm)
			return vm.PowerOnVM_Task.wait_for_completion
		end

		def stop_instance(vm)
			vm.ShutdownGuest

			while vm.summary[:runtime][:powerState] != 'poweredOff'
				sleep 5
			end
		end

		def get_vm_address(vm)
			while true do
				addr = vm.summary[:guest][:ipAddress]

				return addr if not addr.nil?

				sleep 5
			end 
		end
	end
end

