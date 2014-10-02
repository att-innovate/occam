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
require 'yaml'

namespace :apps do
  desc 'App initialization, default initializes all apps.'
  task :init, [:zone, :app] => ['occam:init_hiera', :fetch] do |t, args|
    zone = "#{ROOT}/local/hiera/zones/#{args[:zone] || ZONEINFO}.yaml"
    config = YAML.load_file zone
    apps = args[:app] ? [args[:app]] : config['profile::hiera::config::occam_apps']

    apps.each do |app|
      name = app_name(app)
      puts "Starting initialization of occam app: #{name}"
      if Rake::Task.task_defined?("#{name}:init")
        Rake::Task["#{name}:init"].invoke
      else
        puts "No init task for app: #{name}"
      end
      if File.directory?("puppet/apps/#{name}/profile")
        FileUtils.cp_r("puppet/apps/#{name}/profile/.", 'puppet/modules/profile/')
      end
      if File.directory?("puppet/apps/#{name}/role")
        FileUtils.cp_r("puppet/apps/#{name}/role/.", 'puppet/modules/role/')
      end
      if File.exists?("puppet/apps/#{name}/hiera/#{name}.yaml")
        FileUtils.cp("puppet/apps/#{name}/hiera/#{name}.yaml", 'puppet/hiera/apps/')
      end
    end
  end

  task :fetch, [:zone, :app] do |t, args|
    zone = "#{ROOT}/local/hiera/zones/#{args[:zone] || ZONEINFO}.yaml"
    config = YAML.load_file zone
    apps = args[:app] ? [args[:app]] : config['profile::hiera::config::occam_apps']
    base_cmd = "git clone https://github.com/"

    Dir.chdir("puppet/apps") do
      apps.each do |app|
        name  = app_name(app)
        if Dir[name] == nil
          sh "#{base_cmd}#{app}.git #{name}"
        else
          puts "#{name} already exists. Perhaps you want to apps:update?"
        end
      end
    end
  end

  desc "Remove all managed apps; Seriously, all of them."
  task :clean, [:zone, :app] do |t, args|
    zone = "#{ROOT}/local/hiera/zones/#{args[:zone] || ZONEINFO}.yaml"
    config = YAML.load_file zone
    apps = args[:app] ? [args[:app]] : config['profile::hiera::config::occam_apps']

    apps.each do |app|
      name = app_name(app)
      sh "rm -rf puppet/apps/#{name}"
    end
  end
end
