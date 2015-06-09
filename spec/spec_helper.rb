ENV['RACK_ENV'] = 'test'

require 'json'
require 'webmock/rspec'
require 'rspec/its'
#require 'log4r'
#require 'log4r/yamlconfigurator'

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec
end

WebMock.disable_net_connect!(allow_localhost: false)

#log4r_cfg = Log4r::YamlConfigurator
#log4r_cfg['ENV'] = ENV['RACK_ENV']
#log4r_cfg.load_yaml_file(File.expand_path("../config/#{ENV['RACK_ENV']}/log4r.yaml", File.dirname(__FILE__)))
