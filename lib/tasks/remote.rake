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
hiera_yaml = {
  :hierarchy => [
    "local/secrets",
    "local/fqdns/%{::fqdn}",
    "local/hostgroups/%{::hostgroup}",
    "local/zones/%{::zone}",
    "local/users/users",
    "users/users_occam",
    "cloud",
    "occam",
    "common",
  ],
  :backends => [
    "yaml",
    "gpg",
  ],
  :yaml => {:datadir => "#{OCCAM_DIR}/puppet/hiera"},
  :gpg  => {
    :datadir => "#{OCCAM_DIR}/puppet/hiera",
    :key_dir => "/etc/puppet/keyrings"
  }
}

namespace :remote do
  #desc 'Configure ops node' # It's called from bootstrap.sh
  task :deploy_ops, [:key, :env_root, :env, :user] => 'tmp' do |t,args|

    # Vars
    key_name = args[:key]      || DEFAULT_KEYNAME
    env      = args[:env]      || OC_ENVIRONMENT
    env_root = args[:env_root] || '/var/puppet'
    user     = args[:user]     || 'root'
    date     = `date +"%Y%m%d%H%M%S"`.chomp

    # Fetch repo data
    Net::HTTP.start("apt.puppetlabs.com") do |http|
      resp = http.get("/puppetlabs-release-precise.deb")
      open("tmp/puppetlabs-release-precise.deb", "wb") do |file|
        file.write(resp.body)
      end
    end
    # Install puppet
    run "dpkg -i tmp/puppetlabs-release-precise.deb"
    run "apt-get update"
    run "apt-get upgrade -y"
    run "apt-get install puppet -y"

    # Write temporary hiera file
    File.open('tmp/hiera.yaml', 'w') do |file|
      file.write(hiera_yaml.to_yaml)
    end

    # Run puppet
    modulepath = (["#{OCCAM_DIR}/puppet/modules", "#{OCCAM_DIR}/puppet/occam/modules"] + Dir.glob("#{OCCAM_DIR}/puppet/apps/*/modules")).join(':')
    cmd = "puppet apply --modulepath #{modulepath} "
    cmd << "--hiera_config #{OCCAM_DIR}/tmp/hiera.yaml --pluginsync "
    cmd << "#{OCCAM_DIR}/puppet/manifests/ops_bootstrap.pp"
    run cmd

    # Import GPG keys
    if ! File.exists?('/etc/puppet/keyrings')
      run 'mkdir -p /etc/puppet/keyrings'
      run "tar xzf #{key_name}.tgz"
      if ! File.zero?("#{key_name}.txt")
        run "gpg --homedir=/etc/puppet/keyrings --import #{key_name}.txt"
      end
      run "chown -R puppet:puppet /etc/puppet/keyrings"
      run "chmod g-rwx,o-rwx -R /etc/puppet/keyrings"
    else
      puts "Keyring already exists, skipping..."
    end

    # Insert code in correct place
    run "mkdir -p #{env_root}/environments"
    run "mkdir -p #{env_root}/archive/#{env}/#{date}"
    run "rsync -a -f'- .git/' -f'+ *' #{OCCAM_DIR}/puppet #{env_root}/archive/#{env}/#{date}/"
    run "/bin/rm -f #{env_root}/environments/#{env}"
    run "/bin/ln -s #{env_root}/archive/#{env}/#{date} #{env_root}/environments/#{env}"
    run "rm -rf $(ls -dt1 #{env_root}/archive/#{env}/* | tail -n +6)"
    run "chown -R #{user} #{env_root}"

    # Run puppet and stuff
    run 'rm -rf /tmp/occam-archive'
    run 'service occamengine restart'
    run 'service apache2 restart'
    run 'service puppet stop'
    run 'chown -R puppet:puppet /var/lib/puppet/reports'
    run "puppet agent -t --environment=#{OC_ENVIRONMENT}"
    run 'service rabbitmq-server restart'
    run 'service apache2 restart'
    run 'service rsyslog restart'
    run 'service puppet restart'

  end
end
