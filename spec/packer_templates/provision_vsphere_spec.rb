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

			vsphere_host:      'testhost',
			vsphere_datastore: 'testdatastore',
			vsphere_network:   'testnetwork',
			vsphere_pool:      'testpool',

			base_template:     'testbase',
		)
	end

	before {
		now = double
		allow(now).to receive(:strftime).and_return("2015-09-09-13-55-54")
		allow(DateTime).to receive(:now).and_return(now)

		logger = double
		allow(logger).to receive(:info)
		allow(Logger).to receive(:new).and_return(logger)
	}

	describe "provision_server" do

		before { provision_vsphere.instance_variable_set("@ip", '1.1.1.1')}

		it 'Calls packer' do
			expect(PackerTemplates::Packer).to receive(:build)
			.with(
				'testtemplate.json',
				'null',
				{
					:ssh_address  => '1.1.1.1',
					:server_name  => 'testvm',
					:ssh_username => 'testuser',
					:ssh_password => 'testpass',
				},
				[]
			)
			.and_return(true)

			provision_vsphere.provision_server
		end
	end
end
