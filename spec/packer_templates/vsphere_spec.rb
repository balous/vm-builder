require 'spec_helper'
require 'packer_templates/vsphere'

describe PackerTemplates::Vsphere do
	let (:vsphere) {described_class.new('remote', 'user', 'pass')}
	describe '#initialize' do

		let (:vsphere_api){RbVmomi::VIM}
		let (:connection){double}

		it "calls vsphere connect" do
			expect(vsphere_api).to receive(:connect).with(:host => 'remote', :user => 'user', :password => 'pass', :insecure => true).and_return(connection)
			expect(vsphere.connection).to eq connection
		end
	end
end
