Gem::Specification.new do |s|
	s.name     = 'vm-builder'
	s.version  = '1.0.0'
	s.summary  = "Tools used to build virtual machines"
	s.homepage = 'https://github.com/samepage-labs/vm-builder'
	s.authors  = ["Petr Baloun"]
	s.email    = 'pbaloun@samepage.io',
	s.license  = 'Nonstandard'
	s.files    = [
		"lib/vm_builder/build_vsphere.rb",
		"lib/vm_builder/ovftool.rb",
		"lib/vm_builder/packer.rb",
		"lib/vm_builder/provision_vsphere.rb",
		"lib/vm_builder/script_base.rb",
		"lib/vm_builder/vsphere.rb",
	]
	s.add_runtime_dependency "rbvmomi", '~> 1.8'
	s.add_development_dependency "webmock", '~> 2.1'
	s.add_development_dependency "rspec-its", '~> 1.2'
	s.add_development_dependency "json", '~> 2.0'
end
