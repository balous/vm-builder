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

			if !params[:compute_resource].nil?
                        	host = @connection.serviceInstance.find_datacenter.hostFolder.find(params[:compute_resource])
				relocateSpec.pool = get_resource_pool(host, params[:resource_pool])
				relocateSpec.host = host.host.first
			end

			relocateSpec.datastore = @connection.serviceInstance.find_datacenter.find_datastore(params[:datastore])


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

		def register_instance(params)

			path = "[#{params[:datastore]}]#{params[:path]}"

			# this is not designed to work with vcenter and standalone ESX doesn't seem to support registration to subpool
			pool = @connection.serviceInstance.find_datacenter.hostFolder.children.first.resourcePool
			
			task = @connection.serviceInstance.find_datacenter.vmFolder.RegisterVM_Task(
				:path => path,
				:name => params[:name],
				:asTemplate => false,
				:pool => pool,
			)

			task.wait_for_completion

			if task.info.state != "success"
				raise "Unable to register VM: #{task.info.error.localizedMessage}"
			end
		end

		def get_resource_pool(host, name)

			pool = host.resourcePool

			if ! name.nil?
				pool = pool.traverse(name)
			end

			return pool
		end
	end
end

