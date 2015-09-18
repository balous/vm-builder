require 'packer_templates/build_vsphere'

describe PackerTemplates::BuildVsphere do
	let (:build_vsphere) do
		described_class.new(
			cli_opts: [
				"--vsphere-user", "testuser",
				"--vsphere-pass", "testpass",
			],
			name: "testvm",
			packer_template: "testtemplate",
			ssh_user: 'testuser',
			ssh_pass: 'testpass',

			vsphere_host:      'testhost',
			vsphere_datastore: 'testdatastore',
			vsphere_network:   'testnetwork',
			vsphere_pool:      'testpool',
		)
	end

	before {
		now = double
		now.stub(:strftime).and_return("2015-09-09-13-55-54")
		DateTime.stub(:now).and_return(now)
	}

	describe 'initialize' do
		context 'default values' do
			let (:build_vsphere) {described_class.new(cli_opts: [], name: 'testvm', vsphere_host: 'testhost', vsphere_datastore: 'testdatastore', vsphere_network: 'testnetwork')}

			before do
				allow(ENV).to receive(:[]).with("vsphere_user").and_return("testuser")
				allow(ENV).to receive(:[]).with("vsphere_password").and_return("testpass")
			end

			it {expect(build_vsphere.vsphere_user).to eq "testuser"}
			it {expect(build_vsphere.vsphere_pass).to eq "testpass"}
		end

		context 'some values' do
			it {expect(build_vsphere.vsphere_host).to eq "testhost"}
			it {expect(build_vsphere.vsphere_user).to eq "testuser"}
			it {expect(build_vsphere.vsphere_pass).to eq "testpass"}
			it {expect(build_vsphere.vsphere_pool).to eq "testpool"}
			it {expect(build_vsphere.vsphere_datastore).to eq "testdatastore"}
			it {expect(build_vsphere.vsphere_network).to eq "testnetwork"}
			it {expect(build_vsphere.name).to eq "testvm-2015-09-09-13-55-54"}
			it {expect(build_vsphere.packer_template).to eq "testtemplate"}
			it {expect(build_vsphere.ssh_user).to eq "testuser"}
			it {expect(build_vsphere.ssh_pass).to eq "testpass"}
		end

		context 'missing host' do
			it {expect{described_class.new(cli_opts: [], name: 'testvm', vsphere_datastore: 'testdatastore', vsphere_network: 'testnetwork')}.to raise_error(RuntimeError, "vSphere host must be specified.")}
		end

		context 'missing network' do
			it {expect{described_class.new(cli_opts: [], name: 'testvm', vsphere_host: 'testhost', vsphere_datastore: 'testdatastore')}.to raise_error(RuntimeError, 'Virtual network must be specified.')}
		end
		context 'missing datastore' do
			it {expect{described_class.new(cli_opts: [], name: 'testvm', vsphere_host: 'testhost', vsphere_network: 'testnetwork')}.to raise_error(RuntimeError, 'Datastore must be specified.')}
		end
	end

	describe 'get_variables' do
		subject{build_vsphere.get_variables}

		it { should be_instance_of Hash}
		it do
			now = double
			now.should_receive(:strftime).with('%Y-%m-%d-%H-%M-%S').and_return("2015-09-09-13-55-54")
			DateTime.stub(:now).and_return(now)
			
			should include(
				:vm_name => 'testvm-2015-09-09-13-55-54',
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
			)
		end
	end
end

