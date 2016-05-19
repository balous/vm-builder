require 'packer_templates/provision_vsphere'

describe PackerTemplates::ProvisionVsphere do
	let (:vm_config) {{foo: 'bar'}}

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

			vm_config: vm_config,

			base_template:     'testbase',
		)
	end

	let(:vsphere)  {double(PackerTemplates::Vsphere)}

	let(:instance) do
		i = double(RbVmomi::VIM::VirtualMachine)
		allow(i).to receive(:name).and_return('testvm-2015-09-09-13-55-54')
		i
	end

	before do
		now = double
		allow(now).to receive(:strftime).and_return("2015-09-09-13-55-54")
		allow(DateTime).to receive(:now).and_return(now)

		logger = double
		allow(logger).to receive(:info)
		allow(Logger).to receive(:new).and_return(logger)

		provision_vsphere.instance_variable_set("@vsphere", vsphere)
	end

	describe "#initialize" do
		it {expect(provision_vsphere.vm_config).to include(foo: 'bar')}
		it {expect(provision_vsphere.base_template).to eq 'testbase'}
	end

	describe "#create_server" do
		let(:template) {double(RbVmomi::VIM::VirtualMachine)}

		it 'calls all the api correctly' do
			expect(template).to receive(:name).and_return('testbase')
			expect(vsphere).to receive(:list_templates).and_return([template])
			expect(vsphere).to receive(:create_instance)
				.with(template, {name: 'testvm-2015-09-09-13-55-54', resource_pool: 'testpool', compute_resource: 'testcompute', datastore: 'testdatastore'})
				.and_return(instance)
			expect(vsphere).to receive(:reconfigure_vm).with(instance, vm_config)
			expect(vsphere).to receive(:start_instance).with(instance)
			expect(vsphere).to receive(:get_vm_address).with(instance).and_return('1.1.1.1')
			provision_vsphere.create_server
		end
	end

	describe "#provision_server" do

		before do
			provision_vsphere.instance_variable_set("@vm", instance)
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
					:vsphere_instance => 'testvm-2015-09-09-13-55-54',
				},
				[],
				nil
			)
			.and_return(true)

			provision_vsphere.provision_server
		end
	end

	describe "#reconfigure_vm" do

		shared_examples 'no adapter' do
			it "does nothing" do
				expect(vsphere).to receive(:reconfigure_vm).with(instance, vm_config)
				provision_vsphere.reconfigure_vm
			end
		end

		shared_examples 'single adapter' do |name|
			before do
				provision_vsphere.instance_variable_set("@vm_config", {networks: {'adapter' => 'network'}})
			end

			it "sets network '#{name}'" do
				expect(vsphere).to receive(:reconfigure_vm).with(instance, {networks: {'adapter' => name}})
				provision_vsphere.reconfigure_vm
			end
		end

		before do
			provision_vsphere.instance_variable_set("@vm", instance)
		end

		context 'network param set' do

			it_behaves_like 'no adapter'
			it_behaves_like 'single adapter', 'testnetwork'

			context 'two adapters' do
				before do
					provision_vsphere.instance_variable_set("@vm_config", {networks: {'adapter1' => 'network1', 'adapter2' => 'network2'}})
				end

				it "raises error" do
					expect {provision_vsphere.reconfigure_vm}.to raise_error(RuntimeError, "Unable to set network for multiple adapters")
				end
			end
		end

		context 'no network param set' do
			before do
				provision_vsphere.instance_variable_set("@vsphere_network", nil)
			end

			it_behaves_like 'no adapter'
			it_behaves_like 'single adapter', 'network'

			context 'two adapters' do
				let (:vm_config) {{networks: {'adapter1' => 'network1', 'adapter2' => 'network2'}}}
				before do
					provision_vsphere.instance_variable_set("@vm_config", vm_config)
				end

				it 'passes adapters unchanged' do
					expect(vsphere).to receive(:reconfigure_vm).with(instance, vm_config)
					provision_vsphere.reconfigure_vm
				end
			end
		end
	end

	describe '#create_shapshot' do
		before do
			provision_vsphere.instance_variable_set("@vm", instance)
		end

		it 'calls underlying api correctly' do
			expect(vsphere).to receive(:create_snapshot)
				.with(instance, 'snapshot-name')

			provision_vsphere.create_snapshot('snapshot-name')
		end
	end
end
