require 'pp'
require 'rbvmomi'

module VmBuilder
	class Vsphere

		attr_reader :connection
		def initialize(hostname, username, password)

			@connection = RbVmomi::VIM.connect host: hostname, user: username, password: password, insecure: true

			@watchdog = Thread.new {watch_dog()}
		end

		def watch_dog()
			while true do
				@connection.serviceInstance.CurrentTime()
				sleep 60
			end
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

		def reconfigure_networks(vm, networks)

			changes = []

			networks = [] if networks.nil?

			networks.each do |label, network|
				net = vm.resourcePool.owner.network.find{|n| n.name == network}

				old = vm.config.hardware.device.find{|d| d.deviceInfo.label == 'Network adapter 1'}

				new = old.clone
				new.backing = RbVmomi::VIM::VirtualEthernetCardNetworkBackingInfo(
					:network => net,
					:deviceName => network,
				)

				edit = RbVmomi::VIM.VirtualDeviceConfigSpec(
					operation: :edit,
					device: new
				)

				changes.push(edit)
			end

			return changes
		end

		def create_disk(vm, params)
			disk = RbVmomi::VIM::VirtualDisk()

			disk.key = -1

			disk.controllerKey = vm.config.hardware.device.find{|d| d.to_s =~ /VirtualLsiLogicController/}.key

			disk.backing = RbVmomi::VIM::VirtualDiskFlatVer2BackingInfo(
				diskMode: :persistent,
				fileName: vm.config.files.vmPathName.gsub(/\/.*$/, "/#{params[:fname]}.vmdk"),
				datastore: vm.datastore[0],
				thinProvisioned: true,
			)

			return disk
		end

		def reconfigure_disks(vm, disks)

			disk_count = vm.disks.count

			disks = [] if disks.nil?
			disks.each do |label, params|
				oldDisk = vm.disks.find{|d| d.deviceInfo.label == label}

				if not oldDisk.nil?
					newDisk = oldDisk.dup
					operation = :edit
					file_operation = nil
				else
					newDisk = create_disk(vm, params)
					newDisk.unitNumber = disk_count
					disk_count = disk_count + 1

					operation = :add
					file_operation = :create
				end

				newDisk.capacityInKB = params[:capacity] * 1024 * 1024 if not params[:capacity].nil?

				change = RbVmomi::VIM.VirtualDeviceConfigSpec(
					device: newDisk,
					operation: operation,
					fileOperation: file_operation,
				)

				config = RbVmomi::VIM.VirtualMachineConfigSpec(
					deviceChange: [change],
				)

				vm.ReconfigVM_Task(:spec => config).wait_for_completion
				end

			return 0
		end

		def reconfigure_vm(vm, params)

			deviceChange = []
			deviceChange.concat(reconfigure_networks(vm, params[:networks]))

			config = RbVmomi::VIM.VirtualMachineConfigSpec(
				memoryMB: params[:mem],
				numCPUs: params[:cpus],
				deviceChange: deviceChange,
			)

			vm.ReconfigVM_Task(:spec => config).wait_for_completion

			reconfigure_disks(vm, params[:disks])
		end

		def create_snapshot(vm, name)
			vm.CreateSnapshot_Task(
				name: name,
				memory: false,
				quiesce: false,
			).wait_for_completion
		end

		def create_instance(template, params)

			relocateSpec = RbVmomi::VIM.VirtualMachineRelocateSpec

			if !params[:compute_resource].nil?
                        	host = @connection.serviceInstance.find_datacenter.hostFolder.find(params[:compute_resource])
				relocateSpec.pool = get_resource_pool(host, params[:resource_pool])
				relocateSpec.host = host.host.first
			end

			relocateSpec.datastore = @connection.serviceInstance.find_datacenter.find_datastore(params[:datastore])
			relocateSpec.transform = RbVmomi::VIM.VirtualMachineRelocateTransformation('sparse')

			spec = RbVmomi::VIM.VirtualMachineCloneSpec(
				:location => relocateSpec,
				:powerOn  => false,
				:template => false,
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

			return task.info.result
		end

		def delete_instance(vm)
			task = vm.Destroy_Task

			task.wait_for_completion

			if task.info.state != "success"
				raise "Unable to delete VM: #{task.info.error.localizedMessage}"
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

