###############################################################################
##                                                                           ##
## The MIT License (MIT)                                                     ##
##                                                                           ##
## Copyright (c) 2014 AT&T Inc.                                              ##
##                                                                           ##
## Permission is hereby granted, free of charge, to any person obtaining     ##
## a copy of this software and associated documentation files                ##
## (the "Software"), to deal in the Software without restriction, including  ##
## without limitation the rights to use, copy, modify, merge, publish,       ##
## distribute, sublicense, and/or sell copies of the Software, and to permit ##
## persons to whom the Software is furnished to do so, subject to the        ##
## conditions as detailed in the file LICENSE.                               ##
##                                                                           ##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS   ##
## OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                ##
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    ##
## IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY      ##
## CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT ##
## OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR  ##
## THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                ##
##                                                                           ##
###############################################################################
class String
  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.empty? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

def get_param (env_var, prompt, regex, default='')
  if ! (ENV[env_var])
    return ask("#{prompt} : ") {|q| q.echo = true; q.validate = /#{regex}/; q.default = default}.to_s
  else
    return ENV[env_var]
  end
end

def load_config (path)
  if File.file?(path)
    return YAML.load_file(path)
  else
    abort("No example configuration file in #{path}")
  end
end

def three_octets(ip)
  return ip.split('.').first(3).join('.')
end

namespace :config do
  desc "Generate config file"
  task :generate, [:zonename] do |t, args|
    require 'erb'
    pwd = File.expand_path File.dirname(__FILE__)
    template = "#{pwd}/../files/example_zone.yaml.erb"
    gen = load_config("#{pwd}/../files/generator.yaml")
    default = load_config("#{pwd}/../files/example_zone.yaml")

    filename = args[:zonename] || "example_zone"
    @cfg = Hash.new
    gen['params'].each do |k,v|
      if v['default']
        @cfg[k] = get_param(v['envvar'],v['desc'],v['regex'],default[k])
      else
        @cfg[k] = get_param(v['envvar'],v['desc'],v['regex'])
      end
    end

    zonefile = File.expand_path "#{pwd}/../../puppet/hiera/zones/#{filename}.yaml"
    begin
      File.open(zonefile, 'w') {|f| f.write ERB.new(File.read(template),nil,'-').result}
      puts "I've written basic config in #{zonefile}. Tweak it to your needs and deploy occam."
    rescue Exception => e
      puts "I was unable to write #{file}. Exception: #{e}"
      exit 1
    end
  end
end