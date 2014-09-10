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
namespace :occam do
  desc 'Initialize occam modules'
  task :init => ['occam:init_hiera'] do
    puts 'Initializing occam modules'
    run 'cd puppet/occam && r10k -t -v INFO puppetfile install'
    if File.directory?('puppet/occam/profile')
      FileUtils.cp_r('puppet/occam/profile/.', 'puppet/modules/profile/')
    end
    if File.directory?('local/ssl')
      FileUtils.cp_r('local/ssl/.', 'puppet/modules/profile/files/ssl/')
    end
    if File.directory?('puppet/occam/role')
      FileUtils.cp_r('puppet/occam/role/.', 'puppet/modules/role/')
    end
  end

  task :init_hiera do
    puts 'Initializing hiera'
    if File.directory?('local/hiera')
      FileUtils.cp_r('local/hiera/.', 'puppet/hiera/local/')
    end
  end

  desc 'Clean up modules and hiera dirs'
  task :clean do
    FileUtils.rm_r Dir.glob(['tmp/*', 'puppet/modules/{profile,role}/*', 'puppet/hiera/{apps,local}/*'])
  end

  desc 'Create an archive for deployment'
  task :prepare_archive, [:key] => ['tmp', 'gpg:export', 'occam:init'] do |t, args|
    name = 'occam-archive'
    key = args[:key] || "#{DEFAULT_KEYNAME}.tgz"
    run "tar -czf tmp/#{name}.tgz --exclude '.git*' --exclude './tmp' --exclude .virtualdisks ."
  end

  desc 'Deploy occam to vanilla ubuntu ops server (1st step!)'
  task :deploy_initial, [:server, :port]  => [
    'tmp',
    'occam:clean',
    'apps:init',
    'occam:prepare_archive'
  ] do |t, args|
    host = args[:server] || '192.168.3.10'
    port = args[:port] || 22
    login, password = get_credentials
    zone_file = nil
    zone_file = get_zone if OC_ENVIRONMENT == 'testing'

    send_file('tmp/occam-archive.tgz',host,login,password,port)

    cmds = [
      "mkdir -p #{OCCAM_CONFIG_DIR}",
      "test ! -e #{OCCAM_CONFIG_LOCKFILE}",
      "touch #{OCCAM_CONFIG_LOCKFILE}",
      "echo #{OC_ENVIRONMENT} > #{OCCAM_CONFIG_ENVFILE}"
    ]
    if ! zone_file.nil?
      cmds.concat([
        "echo #{zone_file} > #{OCCAM_CONFIG_ZONEFILE}"
        ])
    end
    cmds.concat([
      'rm -rf occam-archive',
      'mkdir occam-archive',
      'tar xzf occam-archive.tgz -C occam-archive',
      "cd occam-archive && sudo ./utils/bootstrap.sh #{OC_ENVIRONMENT} #{zone_file}",
      ])

    ssh_commands(cmds,host,login,password,port)
  end

  desc 'Deploy a release based on the local occam branch to ops server'
  task :update_code, [:server, :port] => ['tmp',
                                          'occam:clean',
                                          'apps:init',
                                          'occam:prepare_archive'] do |t, args|
    host = args[:server] || '192.168.3.10'
    port = args[:port] || 22
    env_root = args[:env_root] || '/var/puppet'
    user     = args[:user]     || 'root'
    date     = `date +"%Y%m%d%H%M%S"`.chomp
    login, password = get_credentials

    destdir = "#{env_root}/archive/#{OC_ENVIRONMENT}/#{date}"
    envdir = "#{env_root}/environments/#{OC_ENVIRONMENT}"

    send_file('tmp/occam-archive.tgz',host,login,password,port)

    cmds = [
      "mkdir -p #{destdir}",
      'rm -rf occam-archive',
      'mkdir occam-archive',
      "tar xzf occam-archive.tgz -C occam-archive",
      "rsync -a -f'- .git/' -f'+ *' occam-archive/puppet #{destdir}/",
      'service puppet stop',
      "rm #{envdir}",
      "ln -s #{destdir} #{envdir}",
      "rm -rf $(ls -dt1 #{env_root}/archive/#{OC_ENVIRONMENT}/* | tail -n +6)",
      'rm -rf occam-archive*',
      'service puppet start',
      'service apache2 restart',
      'service occamengine restart'
    ]

    ssh_commands(cmds,host,login,password,port)

  end
end
