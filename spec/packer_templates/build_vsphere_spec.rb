require 'packer_templates/build_vsphere'

describe PackerTemplates::BuildVsphere do
	let (:build_vsphere) do
		described_class.new(
			cli_opts: [
				"--vsphere-user", "testuser",
				"--vsphere-pass", "testpass",
			],
			name: "testvm",

			packer_template: "testtemplate.json",
			packer_vars:     {var: 'val'},

			ssh_user: 'testuser',
			ssh_pass: 'testpass',

			vsphere_host:            'testhost',
			vsphere_host_thumbprint: '00:11:22',
			vsphere_datastore:       'testdatastore',
			vsphere_network:         'testnetwork',
			vsphere_pool:            'testpool',
		)
	end

	let (:vsphere) do
		vsphere = double

		allow(PackerTemplates::Vsphere).to receive(:new)
			.with(
				'testhost', 'testuser', 'testpass'
			)
			.and_return(vsphere)
		vsphere
	end

	before {
		now = double
		allow(now).to receive(:strftime).and_return("2015-09-09-13-55-54")
		allow(DateTime).to receive(:now).and_return(now)

		logger = double
		allow(logger).to receive(:info)
		allow(Logger).to receive(:new).and_return(logger)
	}

	describe '#initialize' do
		context 'missing network' do
			it {expect{described_class.new(cli_opts: [], name: 'testvm', vsphere_host: 'testhost', vsphere_datastore: 'testdatastore')}.to raise_error(RuntimeError, 'Virtual network must be specified.')}
		end
	end

	describe '#build_template' do
		context 'Successfull execution' do
			it 'Calls packer' do
				expect(PackerTemplates::Packer).to receive(:build)
				.with(
					'testtemplate.json',
					'vmware-iso',
					{
						:vm_name          => 'testvm-2015-09-09-13-55-54',
						:output_directory => 'testvm-2015-09-09-13-55-54',
						:ssh_username     => 'testuser',
						:ssh_password     => 'testpass',
						:remote_type      => 'esx5',
						:remote_host      => 'testhost',
						:remote_username  => 'testuser',
						:remote_password  => 'testpass',
						:vm_network       => 'testnetwork',
						:remote_datastore => 'testdatastore',
						:cm               => 'puppet',
						:var              => 'val',
					},
					['force']
				)
				.and_return(true)

				build_vsphere.build_template
			end
		end

		context 'Packer fails' do
			before { allow(PackerTemplates::Packer).to receive(:build).and_return false }
			it do
				expect {build_vsphere.build_template()}.not_to raise_error()
			end
		end
	end

	describe '#register_template' do
		it 'Calls Vsphere' do
			expect(vsphere).to receive(:register_instance).with(
				{
					name: 'testvm-2015-09-09-13-55-54',
					path: 'testvm-2015-09-09-13-55-54/testvm-2015-09-09-13-55-54.vmx',
					datastore: 'testdatastore',
				}
			)

			build_vsphere.connect_vsphere
			build_vsphere.register_template
		end
	end

	describe '#export_vm' do
		it 'Calls OvfTool' do
			expect(PackerTemplates::OvfTool).to receive(:export)
				.with(
					dest:            'destination',
					name:            'testvm-2015-09-09-13-55-54',
					host:            'testhost',
					host_thumbprint: '00:11:22',
					user:            'testuser',
					password:        'testpass',
					folder:          nil,
					datastore:       nil,
				)

			build_vsphere.export_vm('destination')
		end
	end

	describe '#delete_vm' do
		it 'Calls Vsphere' do
			expect(vsphere).to receive(:delete_instance)
			build_vsphere.connect_vsphere
			build_vsphere.delete_vm
		end
	end
end

