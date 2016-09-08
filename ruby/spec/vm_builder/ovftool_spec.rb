require 'spec_helper'
require 'vm_builder/ovftool'

describe VmBuilder::OvfTool do
	before do
		  $stdout.stub(:write)
	end

	describe "::export" do
		context "with host thumbprint" do
			it do
				expect(Kernel).to receive(:system).with('ovftool --sourceSSLThumbprint=00:11:22 vi://testuser%40testdomain:testpass@testhost/name destination.ovf')

				described_class.export({
					dest:            'destination',
					name:            'name',
					host:            'testhost',
					user:            'testuser@testdomain',
					host_thumbprint: "00:11:22",
					password:        'testpass',
					folder:          nil,
					datastore:       nil,
				})
			end
		end

		context "adds ovf extension" do
			it do
				expect(Kernel).to receive(:system).with('ovftool vi://testuser%40testdomain:testpass@testhost/name destination.ovf')

				described_class.export({
					dest:      'destination',
					name:      'name',
					host:      'testhost',
					user:      'testuser@testdomain',
					password:  'testpass',
					folder:    nil,
					datastore: nil,
				})
			end
		end

		context "standalone host" do
			it do
				expect(Kernel).to receive(:system).with('ovftool vi://testuser%40testdomain:testpass@testhost/name destination.ovf')

				described_class.export({
					dest:      'destination.ovf',
					name:      'name',
					host:      'testhost',
					user:      'testuser@testdomain',
					password:  'testpass',
					folder:    nil,
					datastore: nil,
				})
			end
		end

		context "vcenter" do
			it do
				expect(Kernel).to receive(:system).with('ovftool vi://testuser%40testdomain:testpass@testhost/datastore/vm/folder/name destination.ovf')

				described_class.export({
					dest:      'destination.ovf',
					name:      'name',
					host:      'testhost',
					user:      'testuser@testdomain',
					password:  'testpass',
					folder:    'folder',
					datastore: 'datastore',
				})
			end
		end

		context "vcenter without folder" do
			it do
				expect{
					described_class.export({
						dest:      'destination',
						name:      'name',
						host:      'testhost',
						user:      'testuser@testdomain',
						password:  'testpass',
						folder:    nil,
						datastore: 'datastore',
					})
				}.to raise_error(ArgumentError)
			end
		end

		context "vcenter without datastore" do
			it do
				expect{
					described_class.export({
						dest:      'destination',
						name:      'name',
						host:      'testhost',
						user:      'testuser@testdomain',
						password:  'testpass',
						folder:    'folder',
						datastore: nil,
					})
				}.to raise_error(ArgumentError)
			end
		end
	end
end

