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
namespace :gpg do
  name    = ENV['GPG_NAME']    || DEFAULT_KEYNAME
  comment = ENV['GPG_COMMENT'] || "Puppet Master"
  email   = ENV['GPG_EMAIL']   || "admin@puppet.example.com"
  home    = ENV['GPG_HOME']    || "#{ENV['HOME']}/.gnupg"
  gpg     = "gpg"

  file "/tmp/gpg.opts" do
    contents = <<-EOF
     %echo Generating a standard key
     Key-Type: RSA
     Key-Length: 2048
     Subkey-Type: RSA
     Subkey-Length: 2048
     Name-Real: #{name}
     Name-Comment: #{comment}
     Name-Email: #{email}
     Expire-Date: 0
     %pubring newkey.pub
     %secring newkey.sec
     # Do a commit here, so that we can later print "done" :-)
     %commit
     %echo done
    EOF

    File.open('/tmp/gpg.opts', 'w') do |f|
      f.puts contents
    end
  end

  #desc "List all available keys"
  task :list do
    run "gpg --list-keys"
  end

  #desc "Add gpg key to local keyring"
  task :local_import, [:key] do |t, args|
    key = args[:key] || name
    puts "#{key}.tgz"
    if not File.exists?("#{key}.tgz") then
      run "gpg --import #{key}"
    else
      run "tar -zxvf #{key}.tgz"
      run "gpg --import #{key}.txt"
    end
  end

  #desc "Create a gpg key"
  task :create => "/tmp/gpg.opts" do
    run "gpg --batch --gen-key /tmp/gpg.opts"
    run "gpg --import newkey.sec"
  end

  #desc "Export a gpg key"
  task :export, [:key] do |t, args|
    key = args[:key] || name
    run "gpg --export-secret-key -a #{key} > #{key}.txt"
    run "tar czf #{key}.tgz #{key}.txt"
    run "rm #{key}.txt"
  end

  #desc "Delete gpg keys and files created"
  task :delete do
    run "rm /tmp/gpg.opts"
    run "gpg --delete-secret-keys #{name}"
    run "gpg --delete-keys #{name}"
  end

  #desc "Encrypts the provided files"
  task :encrypt, [:file, :key] do |t, args|
    key = args[:key] || name
    base = args[:file].sub(".yaml", "")
    run "gpg --trust-model=always --encrypt -o #{base}.gpg -r #{key} #{args[:file]}"
  end

  #desc "Decrypts the provided file"
  task :decrypt, [:file, :key] => "tmp" do |t, args|
    key = args[:key] || name
    base = File.basename(args[:file], ".gpg")
    run "gpg --trust-model=always --decrypt -o tmp/#{base}.yaml -r #{key} #{args[:file]}"
  end
end
