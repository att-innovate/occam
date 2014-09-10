require 'net/http'
require 'net/ssh'
require 'net/scp'
require 'securerandom'
require 'yaml'
require 'rspec/core/rake_task'
require 'highline/import'
require 'erb'
# Ruby 1.8.7 doesn't have require_relative
require './lib/tasks/helper.rb'
require './lib/helpers/virtualbox.rb'
require './lib/helpers/net.rb'

ROOT = File.dirname(__FILE__)
DEFAULT_ZONE = "zone1" # this is the name of the distributed example zone
BASE_BOX="doctorjnupe/precise64_dhcpclient_on_eth7"
PXE_BOX="steigr/pxe"
DISKS_DIR = "#{ROOT}/.virtualdisks"
DISK_SIZE = 1024 * 200
NUM_DISKS = 1
DEMO_VMS = ["ops1", "ctrl1", "comp1", "comp2", "comp3"]
VIRTUALBOX_VERSION="4.3"
VAGRANT_VERSION="1.6"

if ENV['PARALLEL']
  begin
    require 'parallel_tests/tasks'
  rescue LoadError
    puts 'Unable to load parallel_tests/tasks gem'
    puts 'You may forgot to do bundle install'
    puts 'Or it\'s fine, if you\'re trying to bootstrap ops node'
  end
end

directory 'tmp'

DEFAULT_KEYNAME='puppet.example.com'
OCCAM_DIR=File.dirname(__FILE__)

OC_ENVIRONMENT = ENV['OC_ENVIRONMENT'] || 'production'
OCCAM_CONFIG_DIR = '/etc/occam'
OCCAM_CONFIG_LOCKFILE = "#{OCCAM_CONFIG_DIR}/already-deployed"
OCCAM_CONFIG_ENVFILE = "#{OCCAM_CONFIG_DIR}/environment"
OCCAM_CONFIG_ZONEFILE = "#{OCCAM_CONFIG_DIR}/zone"

Dir.glob('lib/tasks/*.rake').each {|r| import r }

# import or apps related tasks
Dir.glob('puppet/apps/*/tasks/*.rake').each {|r| import r }

task :default => :spec

desc "Run rspec tests"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = "--no-drb -r rspec_junit_formatter --format "
  t.rspec_opts += "RspecJunitFormatter -o junit.xml "
  t.rspec_opts += "--format Fuubar --color spec"
  t.pattern = ['spec/*_spec.rb']
end
