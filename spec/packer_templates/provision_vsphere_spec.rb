require 'packer_templates/provision_vsphere'

describe PackerTemplates::ProvisionVsphere do
	let (:provision_vsphere) do
		described_class.new(
			cli_opts: [
				"--vsphere-user", "testuser",
				"--vsphere-pass", "testpass",
			],
			name: "testvm",
			packer_template: "testtemplate.json",
			ssh_user: 'testuser',
			ssh_pass: 'testpass',

			vsphere_host:             'testhost',
			vsphere_datastore:        'testdatastore',
			vsphere_network:          'testnetwork',
			vsphere_pool:             'testpool',
			vsphere_compute_resource: 'testcompute',

			vm_config: {foo: 'bar'},

			base_template:     'testbase',
		)
	end

	before do
		now = double
		allow(now).to receive(:strftime).and_return("2015-09-09-13-55-54")
		allow(DateTime).to receive(:now).and_return(now)

		logger = double
		allow(logger).to receive(:info)
		allow(Logger).to receive(:new).and_return(logger)
	end

	describe "#initialize" do
		it {expect(provision_vsphere.vm_config).to include(foo: 'bar')}
		it {expect(provision_vsphere.base_template).to eq 'testbase'}
	end

	describe "#create_server" do
		let(:vsphere)  {double(PackerTemplates::Vsphere)}
		let(:template) {double(RbVmomi::VIM::VirtualMachine)}
		let(:instance) do
			i = double(RbVmomi::VIM::VirtualMachine)
			allow(i).to receive(:name).and_return('testvm-2015-09-09-13-55-54')
			i
		end

		before { provision_vsphere.instance_variable_set("@vsphere", vsphere)}

		it 'calls all the api correctly' do
			expect(template).to receive(:name).and_return('testbase')
			expect(vsphere).to receive(:list_templates).and_return([template])
			expect(vsphere).to receive(:create_instance)
				.with(template, {name: 'testvm-2015-09-09-13-55-54', resource_pool: 'testpool', compute_resource: 'testcompute', datastore: 'testdatastore'})
				.and_return(instance)
			expect(vsphere).to receive(:reconfigure_vm).with(instance, {:foo=>"bar"})
			expect(vsphere).to receive(:start_instance).with(instance)
			expect(vsphere).to receive(:get_vm_address).with(instance).and_return('1.1.1.1')
			provision_vsphere.create_server
		end
	end

	describe "#provision_server" do

		before do
			vm = double("VM")
			allow(vm).to receive(:name).and_return('vmname')
			provision_vsphere.instance_variable_set("@vm", vm)

			provision_vsphere.instance_variable_set("@ip", '1.1.1.1')
		end

		it 'Calls packer' do
			expect(PackerTemplates::Packer).to receive(:build)
			.with(
				'testtemplate.json',
				'null',
				{
					:ssh_address      => '1.1.1.1',
					:server_name      => 'testvm',
					:ssh_username     => 'testuser',
					:ssh_password     => 'testpass',
					:vsphere_instance => 'vmname',
				},
				[]
			)
			.and_return(true)

			provision_vsphere.provision_server
		end
	end
end
