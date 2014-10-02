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
 require 'socket'
 require 'fileutils'

module NetHelper

  def self.get_private_interfaces
    Hash[Socket.getifaddrs.reject {|ifaddr|
      !ifaddr.addr.ip? ||
      !ifaddr.addr.ipv4_private? ||
      (/vboxnet\d+/.match ifaddr.name)
    }.collect {|ifaddr|
      [ifaddr.name, ifaddr.addr.ip_address]
    }]
  end

  def self.has_forwarding
    require 'os'
    forwarding = "net.ipv4.ip_forward=1" # default linux
    forwarding = "net.inet.ip.forwarding=1" if OS.mac?
    if File.exists? "/etc/sysctl.conf"
      File.open("/etc/sysctl.conf") do |sysctl|
        lines = sysctl.read()
        lines.include? forwarding
      end
    else
      false
    end
  end

  def self.pfnat_temp(network, nic)
    require 'colorize'
    outfile = "#{ROOT}/tmp/pf.conf"

    File.open("/etc/pf.conf") do |pf|
      lines = pf.readlines()
      nat_st = "nat on #{nic} from #{network} -> (#{nic})\n"
      text = lines.join
      tempfile=File.open(outfile, 'w')

      if text.include? nat_st
        puts "pf.conf already contains nat rule".colorize(:green)
        tempfile << text
      elsif m = /nat on ([A-Za-z0-9_]+) from #{network.sub("/", "\/")} -> \([A-Za-z0-9_]+\)/.match(text)
        puts "Found rule for #{network} on interface #{m[1]}!".colorize(:red)
        if not nic.eql? m[1]
          msg = "Your selected nic, #{nic}, would create a forwarding conflict."
          puts msg.colorize(:red)
        end
        print "Would you like to replace with the new rule? [y] "
        answ = STDIN.gets.chomp
        if answ.nil? or answ.eql? "y"
          tempfile << nat_st
        elsif answ.eql? "n"
          tempfile << text
        end
      else
        lines.each do |line|
          tempfile << line
          if line.downcase.include? 'nat-anchor "com.apple/*"'
            tempfile << nat_st if not lines.find {|l| l.include? nat_st }
          end
        end
      end
      tempfile.close
    end
    outfile
  end

  def self.prompt_for_interface
    nic = nil
    intfs =  NetHelper.get_private_interfaces

    while nic.nil?
      puts "Please select a nat interface..."
      intfs.each do |name, ip|
        puts "#{name} => #{ip}"
      end
      print "-> "
      nic = STDIN.gets.chomp
      nic = nil if not intfs.has_key? nic
      puts "Invalid response!" if nic.nil?
    end
    nic
  end
end
