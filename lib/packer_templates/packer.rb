require 'pp'
require 'logger'

module PackerTemplates
	class Packer

		def self.format_build_command(template, build_name, variables, flags)
			command = "packer build"
			command += flags.nil? ? "" : flags.map{|f| " -#{f}"}.join('')
			command += variables.nil? ? "" : variables.map{|name, value| " -var #{name}=\"#{value}\""}.join("")
			command += " -only #{build_name} \"#{template}\""

			return command
		end

		def self.build(template, build_name, variables, flags)

			filename = File.basename(template)
			path     = File.dirname(template)

			retval  = nil
			command = format_build_command(filename, build_name, variables, flags)

			Logger.new(STDOUT).info("Starting command '#{command}'")

			Dir.chdir(path) do
				retval = system(command)
			end

			return retval
		end
	end
end
