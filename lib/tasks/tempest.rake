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
namespace :tempest do

  desc "Makes sure that cloud is sucessfuly installed"
  task :make_sure_that_cloud_is_complete, [:server, :port] do |t, args|
    host = args[:server] || "192.168.3.10"
    port = args[:port] || 22
    login, password = get_credentials

    cmd = ['cd occam-archive && ./utils/wait_for_cloud_complete.rb']

    ssh_commands(cmd,host,login,password,port)

  end
  
  # start of temporary fix
  desc "Start tempest on ops server"
  task :run_tests_on_ops_node, [:server, :port] do |t, args|
    host = args[:server] || "192.168.3.10"
    port = args[:port] || 22
    login, password = get_credentials
    begin
      arr = Array.new
      File.open('tests-disabled').each_line do |l|
        arr << l.chomp
      end
      ignore = arr.join('|').gsub(/^|$/,'"').gsub(/^/,"-e ")
    rescue
      ignore = ''
    end
    cmd = ["cd /var/lib/tempest && source .venv/bin/activate && pip install nose && \
       nosetests tempest #{ignore} --with-xunit --xunit-file=results.xml -q >/dev/null 2>&1; true"]

  ssh_commands(cmd,host,login,password,port)
  end # end of temporary fix

  desc "Fetch junit.xml from ops node"
  task :download_junit_from_host, [:server, :port] do |t, args|
    host = args[:server] || "192.168.3.10"
    port = args[:port] || 22
    login, password = get_credentials

    Net::SCP.start(host, login, :password => password, :port => port) do |scp|
      scp.download!("/var/lib/tempest/results.xml", "tempest.xml")
    end
  end
end
