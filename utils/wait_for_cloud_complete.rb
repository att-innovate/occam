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

require 'timeout'

# wait three hours
timeout = 3 * 60 * 60

$required_nodes = ['ctrl1','comp1','comp2','ops1','comp3','comp4','comp5']

$rn_line = $required_nodes.map{ |a| "hostname=#{a}" }.join(' or ').gsub(/^|$/,"'").gsub(/^/,'-S ')

def kick_occam_nodes
  output = "/usr/bin/mco ping 2>/dev/null | grep occam"
  out =  `#{output}`.split(/\n/).map{ |a| a = $1 if a =~ /^(.*?)\s.*/ }
  if out.length > 0
    out.each do |n|
      puts "Kicking #{n} node"
      `/usr/bin/mco puppet runonce -S hostname=#{n}`
    end
  end
end

def cluster_complete?
  output = "/usr/bin/mco ping #{$rn_line} 2>/dev/null | grep time"
  out =  `#{output}`.split(/\n/).map{ |a| a = $1 if a =~ /^(.*?)\s.*/ }
  if out.sort == $required_nodes.sort
    true
  else
    kick_occam_nodes
    false
  end
end

def puppet_complete?
  output = "/usr/bin/mco puppet status #{$rn_line} 2>/dev/null"
  out = `#{output}`
  if out =~ /idling = (\d+)/
    if $1.to_i == $required_nodes.length
      true
    else
      false
    end
  end
end

def no_fails?
  output = "/usr/bin/mco puppet summary #{$rn_line}  2>/dev/null"
  out = `#{output}`
  if out =~ /Failed resources:.*?min:\s+(.*?)\s+max:\s+(.*?)\s+/
    if $1 == "0.0" and $2 == "0.0"
      true
    else
      false
    end
  end
end

begin
  Timeout.timeout(timeout) do
    until cluster_complete?
      puts "Waiting for all the nodes to come up. Retrying in 10s"
      sleep 10.0
    end

    puts "Cluster is good to go. Performing puppet run."

    `/usr/bin/mco puppet runonce >/dev/null 2>&1`

    until puppet_complete?
      puts "Waiting for all the nodes to finish applying catalog. Retrying in 10s"
      sleep 10.0
    end

    puts "Cluster is good to go. Performing one last puppet run."

    `/usr/bin/mco puppet runonce >/dev/null 2>&1`

    until puppet_complete?
      puts "Waiting for all the nodes to finish applying catalog. Retrying in 10s"
      sleep 10.0
    end

    print "Cluster should be fine. Making sure..."
    if no_fails?
      puts "Yup. It's fine."
    else
      puts "Nope. We've got some fails."
      puts "Quitting!"
      exit 1
    end

  end

rescue Timeout::Error
  puts 'Waited too long. Quitting'
  exit 1
end
