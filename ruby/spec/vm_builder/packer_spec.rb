require 'spec_helper'
require 'vm_builder/packer'

describe VmBuilder::Packer do
	describe "::format_build_command" do
		context "multiple flags and vars" do
			it do
				expect(described_class.format_build_command('template.json', 'vmware-iso', {:var1 => 'val1', :var2 => 'val2'}, ['debug', 'force'], nil))
				       .to eq 'packer build -debug -force -var var1="val1" -var var2="val2" -only vmware-iso "template.json"'
			end
		end

		context "no flags and vars" do
			it do
				expect(described_class.format_build_command('template.json', 'vmware-iso', {}, [], nil))
				       .to eq 'packer build -only vmware-iso "template.json"'
			end
		end

		context "nil flags and vars" do
			it do
				expect(described_class.format_build_command('template.json', 'vmware-iso', nil, nil, nil))
				       .to eq 'packer build -only vmware-iso "template.json"'
			end
		end

		context "one flag" do
			it do
				expect(described_class.format_build_command('template.json', 'vmware-iso', {}, ['debug'], nil))
				       .to eq 'packer build -debug -only vmware-iso "template.json"'
			end
		end
		context "one var" do
			it do
				expect(described_class.format_build_command('template.json', 'vmware-iso', {:var1 => 'val1'}, [], nil))
				       .to eq 'packer build -var var1="val1" -only vmware-iso "template.json"'
			end
		end
		context "with var_file" do
			it do
				expect(described_class.format_build_command('template.json', 'vmware-iso', {:var1 => 'val1'}, [], "var-file"))
				       .to eq 'packer build -var-file "var-file" -var var1="val1" -only vmware-iso "template.json"'
			end
		end
	end
end

