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
    desc "Validate the Occam environment and dependencies"
    task :validate, [:zone] => [
        :requires, 
        :validate_virtualbox, 
        :validate_vagrant,
        :validate_ruby,
        :check_mac_firewall,
        :verify_nat,
        ] do

    end

    task :requires do
        require "colorize"
        require 'os'
        require 'yaml'
    end

    task :validate_vagrant do
        version=`vagrant --version 2>&1`.chomp.split(" ").last

        if not $?.exitstatus.eql? 0
            msg = "Vagrant not found in path! Is Vagrant installed?"
            puts msg.colorize(:red)
        elsif Gem::Version.new(version) < Gem::Version.new(VAGRANT_VERSION)
            msg = "You should upgrade Vagrant."
            msg << "Expected #{VAGRANT_VERSION}, Found #{version}\n"
            puts msg.colorize(:red)
        else
            puts "Vagrant #{version}... OK".colorize(:green)
        end
    end

    task :validate_virtualbox do
        version=`VBoxManage --version 2>&1`.chomp
        if not $?.exitstatus.eql? 0
            msg = "VBoxManage not found in path! Is Virtualbox installed?"
            puts msg.colorize(:red)
        elsif Gem::Version.new(version) < Gem::Version.new(VIRTUALBOX_VERSION)
            msg = "You should upgrade Virtualbox."
            msg << "Expected #{VIRTUALBOX_VERSION}, Found #{version}"
            puts msg.colorize(:red)
        else
            puts "Virtualbox #{version}... OK".colorize(:green)
        end
    end

    task :validate_ruby do
        version = File.open("#{ROOT}/.ruby-version").read.chomp
        if RUBY_VERSION.eql? version
            puts "Ruby version #{version}.... OK".colorize(:green)
        else
            msg = "Unexpected Ruby version. "
            msg << "Expected #{version}, Found #{RUBY_VERSION}"
            puts msg.colorize(:red)
        end
    end

    task :check_mac_firewall do
        if OS.mac?
            status=`defaults read /Library/Preferences/com.apple.alf globalstate`.chomp
            if not status.eql? "0"
                msg = "Detected OS X Firewall: Enabled. This could break NAT'ing."
                puts msg.colorize(:red)
            else
                msg = "Detected OS X Firewall: Disabled... OK"
                puts msg.colorize(:green)
            end
        end
    end

    task :verify_nat, :zone do |task,args|
       zone_name = args[:zone] || DEFAULT_ZONE
       zone = "#{ROOT}/local/hiera/zones/#{zone_name}.yaml"
       config = YAML.load_file zone
       network = config['mgmt_network']

       if OS.mac?
            output=`defaults read /System/Library/LaunchDaemons/com.apple.pfctl ProgramArguments`
            if output.eql? "(\n    pfctl,\n    \"-f\",\n    \"/etc/pf.conf\",\n    \"-e\"\n)\n"
                puts "Pfctl plist.... OK".colorize(:green)
            else
                puts "Pfctl plist may not be configured!".colorize(:red)
            end

           enabled=`sysctl net.inet.ip.forwarding`.chomp.split.last.to_i 
           if enabled.eql? 1
                puts "IP Forwarding Enabled.... OK".colorize(:green)
            else
                puts "IP Forwarding not enabled!".colorize(:red)
           end
        elsif OS.linux?
           expected = "POSTROUTING -s #{network} -j MASQUERADE" 
           found  = `iptables -S -t nat`.include? expected
           if found
                puts "NAT rules found.... OK".colorize(:green)
            else
                puts "Could not find NAT rules!".colorize(:red)
            end

           enabled=`sysctl net.ipv4.ip_forward`.chomp.split.last.to_i 
           if enabled.eql? 1
                puts "IP Forwarding Enabled.... OK".colorize(:green)
            else
                puts "IP Forwarding not enabled!".colorize(:red)
           end
       end 
    end
end