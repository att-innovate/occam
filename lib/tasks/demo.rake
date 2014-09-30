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

namespace :demo do
  directory DISKS_DIR

  task :load_requires do
    require 'yaml'
    require 'erb'
    require 'os'
    require 'fileutils'
    require 'colorize'
  end

  desc 'Initialize the demo environment.'
  task :init, [:zone, :disks_directory] => [:load_requires,
                                            :copy_demo_local,
                                            "occam:init",
                                            "apps:init",
                                            :warning,
                                            "tmp",
                                            :createif,
                                            :add_boxes,
                                            "#{DISKS_DIR}/ctrl1_ipxe.dsk",
                                            "#{DISKS_DIR}/comp1_ipxe.dsk",
                                            "#{DISKS_DIR}/comp2_ipxe.dsk",
                                            "#{DISKS_DIR}/comp3_ipxe.dsk",
                                            :create_disks,
                                            "#{ROOT}/Vagrantfile",
                                            :nat,
                                            :ops_up,
                                            :setup_ops_root,
                                            :deploy_ops,
  ] do

    puts "Warning!! Your firewall settings may block the forwarding rules".colorize(:red)
    puts "Warning!! This is a known issue particularly on OS X.".colorize(:red)
  end

  task :warning do
    msg = "WARNING! This script may make changes to system files/state"
    puts msg.colorize(:red)
    if OS.mac?
      puts "Specifically: "
      puts "    - /etc/pf.conf"
      puts "    - net.inet.ip.forwarding=1"
      puts "    - /System/Library/LaunchDaemons/com.apple.pfctl.plist"
      puts "    - /etc/sysctl.conf"
    end
    puts "Continue [n|no|y|yes] (default no)? "
    answ = STDIN.gets.chomp

    answ = "no" if answ.empty?
    if answ.eql? "no" or answ.eql? "n"
      puts "Check you later!"
      exit
    elsif not answ.eql? "yes" and not answ.eql? "y"
      puts "I do not recognize your response!"
      exit
    end
  end

  desc "Starts the vagrant ops node"
  task :ops_up do
      `vagrant status ops1 | grep ops1 | grep running`
      if $?.exitstatus.eql? 0
        puts "Detecting a running vm ops1."
        puts "Please resolve to avoid unexpected outcomes."
      else
        sh "vagrant up ops1 --provider=virtualbox"
      end
  end

  desc "Destroys the vagrant ops node"
  task :ops_destroy do
    sh "vagrant destroy -f ops1"
  end

  desc "Starts the vagrant ctrl node"
  task :ctrl_up do
    sh "vagrant up ctrl1 --provider=virtualbox"
  end

  desc "Destroys the vagrant ctrl node"
  task :ctrl_destroy do
    sh "vagrant destroy -f ctrl1"
  end

  file "#{ROOT}/Vagrantfile", [:zone, :disks_directory] => "#{ROOT}/lib/templates/Vagrantfile.erb" do |task, args|
    template = File.open(task.prerequisites.first).read()
    @zone = args[:zone] || DEFAULT_ZONE
    @disks_directory = args[:disks_directory] || DISKS_DIR

    renderer = ERB.new(template)
    File.open(task.name, "w+") do |file|
      puts "Generating Vagrantfile...."
      file.write(renderer.result())
    end
  end

  task :nat, [:zone] => [:load_requires]  do |task, args|
    zone_name = args[:zone] || DEFAULT_ZONE
    zone = "#{ROOT}/local/hiera/zones/#{zone_name}.yaml"
    config = YAML.load_file zone
    network = config['mgmt_network']

    if OS.mac?
      sh "sudo sysctl -w net.inet.ip.forwarding=1"
      if not NetHelper.has_forwarding
        sh "sudo bash -c 'echo net.inet.ip.forwarding=1 >> /etc/sysctl.conf'"
      end
      puts "Make changes persistent..."
      sh "sudo defaults write /System/Library/LaunchDaemons/com.apple.pfctl ProgramArguments '(pfctl, -f, /etc/pf.conf, -e)'"
      if (File.stat('/System/Library/LaunchDaemons/com.apple.pfctl.plist').mode & 07777) == 0644 then
        puts "Setting pfctl Plist permissions...."
        sh "sudo chmod 644 /System/Library/LaunchDaemons/com.apple.pfctl.plist"
      else
        puts "pfctl Plist has valid permissions..."
      end

      sh "sudo plutil -convert xml1 /System/Library/LaunchDaemons/com.apple.pfctl.plist"

      nic = NetHelper.prompt_for_interface

      sh "cp /etc/pf.conf #{ROOT}/tmp/pf.conf.orig"
      sh "sudo cp #{NetHelper.pfnat_temp(network, nic)} /etc/pf.conf"
      sh "sudo pfctl -f /etc/pf.conf"
    elsif OS.linux?
      sh "sudo sysctl -w net.ipv4.ip_forward=1"
      sh "sudo iptables -t nat -I POSTROUTING -s #{network} -j MASQUERADE"
      puts "To make nat'ing permanent you must: "
      puts "- Add net.ipv4.ip_forward=1 to /etc/sysctl.conf"
      puts "- Add the iptables nat rule to your firewall rules or in /etc/rc.local"
    end
  end

  task :setup_ops_root, [:pubkey, :zone] do |task,args|
    zone_name = args[:zone] || DEFAULT_ZONE
    pubkey = args[:pubkey] || "~/.vagrant.d/insecure_private_key"
    zone = "#{ROOT}/local/hiera/zones/#{zone_name}.yaml"
    config = YAML.load_file zone
    ops = config['puppet_address']
    cmd = "echo root:root | sudo chpasswd"
    sh "ssh vagrant@#{ops} -i #{pubkey} '#{cmd}'"
  end

  task :deploy_ops, [:environment, :zone] do |task, args|
    environment = args[:environment] || "testing"
    zone_name = args[:zone] || DEFAULT_ZONE
    pubkey = args[:pubkey] || "~/.vagrant.d/insecure_private_key"
    zone = "#{ROOT}/local/hiera/zones/#{zone_name}.yaml"
    config = YAML.load_file zone
    ops = config['puppet_address']

    cmd = "OPSUSERNAME='root' OPSPASSWORD='root' OC_ENVIRONMENT=#{environment} "
    cmd << "ZONEFILE=#{zone_name} rake -v occam:deploy_initial[#{ops}]"
    sh cmd
  end

  DEMO_VMS.each do |vm|
    file "#{DISKS_DIR}/#{vm}_ipxe.dsk" =>  [DISKS_DIR, :add_boxes] do |task|
      cp task.prerequisites.last, task.name, :verbose => true
    end
  end

  task :create_disks do
    size = 1024 * 200
    DEMO_VMS.each do |vm|
      (1..NUM_DISKS).each do |num|
        path = "#{DISKS_DIR}/#{vm}_disk#{num}.vdi"
        if not File.exists? path
          puts "Creating #{vm}_disk#{num}..."
          VirtualBox.create_disk(path, size)
        else
          puts "#{vm}_disk#{num} exists. Doing nothing."
        end
      end

    end
  end

  task :createif, [:zone] do |t, args|
    zone_name = args[:zone] || DEFAULT_ZONE
    zone = "#{ROOT}/local/hiera/zones/#{zone_name}.yaml"
    if not File.exists? zone
      raise "Could not find requested zone: #{zone_name}!"
    end

    config = YAML.load_file zone

    if net = VirtualBox.get_network(config['mgmt_gateway'])
      puts "Found Management Network: #{net}"
      puts "Disabling DHCP on #{net}..."
      VirtualBox.disable_dhcp(net)
    else
      puts "Creating Management Network..."
      network = VirtualBox.create_hostonlyif config['mgmt_gateway'], "255.255.255.0"
      puts "Management Network Created on '#{network}'"
    end

    if net = VirtualBox.get_network(config['cloud_public_net_gateway'])
      puts "Found Public Network: #{net}"
      puts "Disabling DHCP on #{net}..."
      VirtualBox.disable_dhcp(net)
    else
      puts "Creating Public Network..."
      network = VirtualBox.create_hostonlyif config['cloud_public_net_gateway'], "255.255.255.0"
      puts "Public Network Created on '#{network}'"
    end
  end

  task :add_boxes do
    [BASE_BOX, PXE_BOX].each do |box|
      code, output = VirtualBox.add_box(box)
      if code.eql? 2
        puts "#{box} already exists!"
      elsif code.eql? 1
        puts "Add box #{box} failed with output: "
        puts output
      else
        puts "Added box #{box}"
      end
    end
    output = `vagrant box list | grep steigr`
    m = /.*\(virtualbox, ([\d\.]+)\)/.match output
    path = "#{ENV['HOME']}/.vagrant.d/boxes/steigr-VAGRANTSLASH-pxe/"
    path << "#{m[1]}/virtualbox/ipxe.dsk"

    DEMO_VMS.each do |vm|
      Rake::Task["#{DISKS_DIR}/#{vm}_ipxe.dsk"].enhance ["#{path}"]
    end
  end

  desc "Cleans out all demo generated files"
  task :clean, [:zone] do  |t, args|
    zone_name = args[:zone] || DEFAULT_ZONE
    zone = "#{ROOT}/local/hiera/zones/#{zone_name}.yaml"

    DEMO_VMS.each do |vm|
      puts "vagrant destroy --force #{vm}"
      `vagrant destroy --force #{vm}`
    end
    sh "rm -rf #{DISKS_DIR}"

    config = YAML.load_file zone
    ['cloud_public_net_gateway', 'mgmt_gateway'].each do |net|
      vboxnet = VirtualBox.get_network(config[net])
      if not vboxnet.nil?
        puts "Removing #{net} network #{vboxnet}..."
        VirtualBox.delete_hostonlyif vboxnet
      else
        puts "#{net} not found."
      end
    end
  end

  task :copy_demo_local do
    if File.exists? "#{ROOT}/local"
      puts "You have an existing 'local' directory!".colorize(:red)
      puts "There is no guarantee your local config work with the demo".colorize(:red)
    else
      FileUtils.cp_r("#{ROOT}/lib/files/examples/demo/local", "#{ROOT}")
    end
  end
end
