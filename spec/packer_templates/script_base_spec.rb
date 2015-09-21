require 'packer_templates/script_base'

describe PackerTemplates::ScriptBase do
	let (:script) do
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
		allow(now).to receive(:strftime).and_return("2015-09-09-13-55-54")
		allow(DateTime).to receive(:now).and_return(now)
	}

	describe 'initialize' do
		context 'default values' do
			let (:script) {described_class.new(cli_opts: [], name: 'testvm', vsphere_host: 'testhost', vsphere_datastore: 'testdatastore', vsphere_network: 'testnetwork')}

			before do
				allow(ENV).to receive(:[]).with("vsphere_user").and_return("testuser")
				allow(ENV).to receive(:[]).with("vsphere_password").and_return("testpass")
			end

			it {expect(script.vsphere_user).to eq "testuser"}
			it {expect(script.vsphere_pass).to eq "testpass"}
		end

		context 'some values' do
			it {expect(script.vsphere_host).to eq "testhost"}
			it {expect(script.vsphere_user).to eq "testuser"}
			it {expect(script.vsphere_pass).to eq "testpass"}
			it {expect(script.vsphere_pool).to eq "testpool"}
			it {expect(script.vsphere_datastore).to eq "testdatastore"}
			it {expect(script.vsphere_network).to eq "testnetwork"}
			it {expect(script.name).to eq "testvm-2015-09-09-13-55-54"}
			it {expect(script.packer_template).to eq "testtemplate"}
			it {expect(script.ssh_user).to eq "testuser"}
			it {expect(script.ssh_pass).to eq "testpass"}
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

	describe 'go' do
		it {expect {script.go}.to raise_error(RuntimeError, "Not implemented.")}
	end
end

