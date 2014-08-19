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
#!/usr/bin/env ruby

$image_path_base = '/dev/vg_vm-storage/'
$base_domain = 'ops-template'
$ip_to_replace = '192.168.3.101'
$new_ip = '192.168.3.10'
$pool_name = 'real_vm_storage'

unless ARGV.length == 2
  puts 'script takes exactly two arguments'
  exit 1
end

unless (ARGV[0] == 'start' or ARGV[0] == 'stop')
  puts 'second argument should be start or stop'
  exit 1
end

def start (vm_name,base_domain,path)
  image_path = path + vm_name

  command('cloning VM',"virt-clone --original #{base_domain} --name #{vm_name} --file #{image_path}")
  command('editing ipaddress',"virt-edit -d #{vm_name} /etc/network/interfaces -e 's/#{$ip_to_replace}/#{$new_ip}/'")
  command("starting VM #{vm_name}","virsh start #{vm_name}")

  puts "Finished!"
end

def stop (vm_name,base_path)
  command("stopping #{vm_name}", "virsh destroy #{vm_name}")
  command("undefining #{vm_name}", "virsh undefine #{vm_name}")
  command("deleting storage #{vm_name}", "virsh vol-delete #{vm_name} --pool #{$pool_name}")

  puts "Finished!"
end

def command (title,command)
  puts command
  `#{command}`
  if $? != 0
    puts "Something went wrong during #{title}"
    exit 2
  end
end

if ARGV[0] == 'start'
  start(ARGV[1], $base_domain, $image_path_base)
else
  stop(ARGV[1], $image_path_base)
end
