require 'settingslogic'
require 'yaml'

## We allow for 2 configuration files. If one were to
## check their application.yml file into a publicly accessible
## repository, they could store their sensitive configuration
## or local db setttings in the application_local.yml file.
class Hash; include DeepSymbolizable; end
class SfOpticon
  class Settings < Settingslogic
    config_file = File.join(ENV['SFOPTICON_HOME'], 'application.yml')
    override_file = File.join(ENV['SFOPTICON_HOME'], 'application_local.yml')
    source config_file

    if File.exist? override_file
      instance.deep_merge!(new(override_file))
    end
    begin
      load!
    rescue SyntaxError
      abort "Syntax error in settings file " + source + ". Please verify configuration settings."
    end
  end
end
