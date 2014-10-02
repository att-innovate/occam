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
def ssh_commands(cmds,host,login,password,port)
  if ! cmds.kind_of?(Array)
    raise 'Command list is not an array'
  end
  cmds.each do |cmd|
    $stdout.write("Running command: #{cmd}\n")
      ssh = Net::SSH.start(host, login, :password => password, :port => port)
      channel = ssh.open_channel do |ch|
        ch.exec cmd do |ch, success|
          raise "Could not execute command: #{cmd}" unless success

          ch.on_data          { |c, data| $stdout.write(data) }
          ch.on_extended_data { |c, type, data| $stderr.write(data) }

          ch.on_request('exit-status') do |ch, data|
            exit_code = data.read_long
            if (cmd =~ /^test/ and exit_code == 1)
              msg = "#{OCCAM_CONFIG_LOCKFILE} exists. Occam already deployed on this server\n"
              msg += 'Please use rake occam:update_code instead!'
              raise msg
            # we do accept 4 and 6 as long as we have deprecation warnings
            elsif (cmd =~ /puppet agent -t.*/ and not [0, 2, 4, 6].include? exit_code) or
              (cmd !~ /puppet agent -t.*/ and exit_code != 0)
              msg = "Rake Task failed on command '#{cmd}' with exit code #{exit_code}"
              raise msg
            end
          end

          ch.on_request('exit-signal') do |ch, data|
            exit_code = data.read_long
            if exit_code != 0
              msg = "Rake Task failed on command '#{cmd}' with exit code #{exit_code}"
              msg += 'Please see tmp/output.log for details'
              raise msg
            end
          end
          ch.on_close { puts "Completed #{cmd}" }
        end
      end
      channel.wait
  end
end

def send_file(file,host,login,password,port)
  print "Sending archive to #{host}..."
  Net::SCP.start(host, login, :password => password, :port => port) do |scp|
    scp.upload(file, '.')
  end
  puts "Done"
end

def get_credentials
  if (ENV['OPSUSERNAME'] && ENV['OPSPASSWORD'])
    l = ENV['OPSUSERNAME']
    p = ENV['OPSPASSWORD']
  else
    l = ask("Enter username: ") {|q| q.echo = true }
    p = ask("Enter password: ") {|q| q.echo = false }
  end
  return l,p
end

def get_zone
  if ! ENV['ZONEFILE']
    zonefile = ask('Enter zone file to use (without path & extension): ') {|q| q.echo = true }
  else
    zonefile = ENV['ZONEFILE']
  end
  return zonefile
end

def get_apps
  zone_path = 'puppet/hiera/local/zones'
  zone = get_zone
  zonefile = "#{zone_path}/#{zone}.yaml"

  if File.exists?(zonefile)
    zoneyaml = YAML.load_file(zonefile)
  else
    abort("Cannot read zone file #{zonefile}")
  end
  return zoneyaml['profile::hiera::config::occam_apps']
end

def run cmd
  puts "Performing #{cmd}"
  sh cmd do |ok, res|
    if cmd =~ /puppet agent -t.*/
      puts 'OK'
    else
      if !ok
        raise "Command #{cmd} failed with exit code #{res.exitstatus}"
      else
        puts 'OK'
      end
    end
  end
end

def app_name(reference)
  reference.split("occam-").last
end
