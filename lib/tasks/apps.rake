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
namespace :apps do
  desc 'App initialization'
  task :init, [:app] => ['occam:init_hiera'] do |t, args|
    app = args[:app]
    Rake::Task["#{app}:init"].invoke
  end
  
  desc 'All apps initialization'
  task :init_all => ['occam:init_hiera'] do
    apps = get_apps
    apps.each do |app|
      puts "Starting initialization of occam app: #{app}"
      if Rake::Task.task_defined?("#{app}:init")
        Rake::Task["#{app}:init"].invoke
      else
        puts "No init task for app: #{app}"
      end
      if File.directory?("puppet/apps/#{app}/profile")
        FileUtils.cp_r("puppet/apps/#{app}/profile/.", 'puppet/modules/profile/')
      end
      if File.directory?("puppet/apps/#{app}/role")
        FileUtils.cp_r("puppet/apps/#{app}/role/.", 'puppet/modules/role/')
      end
      if File.exists?("puppet/apps/#{app}/hiera/#{app}.yaml")
        FileUtils.cp("puppet/apps/#{app}/hiera/#{app}.yaml", 'puppet/hiera/apps/')
      end
    end
  end
end
