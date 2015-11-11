require 'pp'
require 'logger'
require 'cgi'

module PackerTemplates
	class OvfTool 

		def self.export(params)

			user = CGI.escape(params[:user])
			if (params[:datastore].nil? ^ params[:folder].nil?)
				raise ArgumentError, "Datastore and folder parameters must be both set or unset."
			end

			dest = params[:dest]
			dest += ".ovf" if not dest =~ /\.ovf$/

			paths = []
			paths.push(params[:datastore]) if not params[:datastore].nil?
			paths.push('vm')               if not params[:datastore].nil?
			paths.push(params[:folder])    if not params[:folder].nil?
			paths.push(params[:name])

			path = paths.join('/')

			command = "ovftool vi://#{user}:#{params[:password]}@#{params[:host]}/#{path} #{dest}"

			Logger.new(STDOUT).info("Starting command '#{command}'")

			retval = Kernel.system(command)

			return retval
		end
	end
end

