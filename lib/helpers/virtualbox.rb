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

module VirtualBox
    @command = "VBoxManage"
  class << self
    attr_accessor :command

    ["ostypes", "hostdvds", "hostfloppies", "intnets",
     "bridgedifs", "hostonlyifs", "natnets", "dhcpservers", "hostinfo",
     "hddbackends", "hdds", "dvds", "floppies", "usbhost",
     "usbfilters", "systemproperties", "extpacks"].each do |item|
     define_method(item) do
       self.list(item)
     end
   end

  end
    
  def self.list(items)
    `#{self.command} list #{items}`.split("\n\n").collect {|n|
      n.split("\n")
    }.collect do |net|
      Hash[net.compact.collect {|l| 
        l.split(":", 2)
      }.collect {|keys| 
          keys.collect {|item| item.strip
          }
      }]
    end
  end

  def self.disable_dhcp(network)
    `#{self.command} dhcpserver remove --ifname #{network} 2>&1`
  end

  def self.get_network(gateway)
    network = nil
    self.hostonlyifs.each do |net|
      if net['IPAddress'].eql? gateway
        network = net['Name']
      end
    end
    network
  end

  def self.create_hostonlyif(ip, netmask)
    output = `#{self.command} hostonlyif create 2>&1`
    m = /.* '(vboxnet\d+)' was/.match output
    network = m[1]
    `VBoxManage hostonlyif ipconfig #{network} --ip #{ip} --netmask #{netmask} 2>&1`
    self.disable_dhcp network
    network
  end

  def self.create_disk(path, size)
      `VBoxManage createhd --filename #{path} --size #{size} 2>&1`
  end

  def self.add_box(box)
    output = `vagrant box add --provider virtualbox #{box} 2>&1`
    exit_code = $?.exitstatus
    if exit_code.eql? 1 and 
      /.*The box you're attempting to add already exists.*/.match output then
      exit_code = 2
    end
    return exit_code, output
  end

  def self.delete_hostonlyif(network)
    `VBoxManage hostonlyif remove #{network} 2>&1`
    $?.exitstatus
  end
end
