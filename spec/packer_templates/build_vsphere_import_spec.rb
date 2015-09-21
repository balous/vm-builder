require 'packer_templates/build_vsphere_import'

describe PackerTemplates::BuildVsphereImport do
	let (:build_vsphere) do
		described_class.new(
			cli_opts: [
				"--vsphere-user", "testdomain/testuser",
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

			cloudinit:        true,
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

	describe 'import_vm' do

		context 'Successful import' do
			it 'Executes ovftool command' do
				expect(build_vsphere).to receive(:system)
					.with("ovftool --name=\"testvm-2015-09-09-13-55-54\" --datastore=\"testdatastore\" --network=\"testnetwork\" \"./output-vmware-iso/testtemplate.vmx\" \"vi://testdomain%2Ftestuser:testpass@testhost\"")
					.and_return(true)

				build_vsphere.import_vm()
			end
		end

		context 'Import fails' do
			before { allow(build_vsphere).to receive(:system).and_return false }
			it do
				expect {build_vsphere.import_vm()}.to raise_error(RuntimeError, /Unable to import VM/)
			end
		end
	end

	describe 'build_vm' do
		before do
			allow(build_vsphere).to receive(:system).and_return(true)
		end

		context 'Successfull execution' do
			it 'Calls packer' do
				expect(PackerTemplates::Packer).to receive(:build)
					.with(
						'testtemplate.json',
						'vmware-iso',
						{:ssh_username=>"testuser", :ssh_password=>"testpass", :cm=>"puppet", :second_disk_path=>File.absolute_path("cloudinit.vmdk"), :second_disk_present=>"TRUE"},
						['force']
					)
					.and_return(true)

				build_vsphere.build_vm
			end
		end

		context 'Packer fails' do
			before { allow(PackerTemplates::Packer).to receive(:build).and_return false }
			it do
				expect {build_vsphere.build_vm()}.to raise_error(RuntimeError, /Unable to build VM/)
			end
		end
	end
end

