require 'dockerspec'

describe 'ovftool' do
	describe command('ovftool --version') do
		its(:stdout) {should match /^VMware ovftool/}
	end
end
describe 'packer' do
	describe command('packer version') do
		its(:stdout) {should match /^Packer/}
	end
end
