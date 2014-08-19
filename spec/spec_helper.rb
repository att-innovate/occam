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
require 'pp'
require 'open3'

$ignore_list = 'spec/lint-ignore-list'
$include_list = 'spec/lint-tested-directories'
$base_dirs = Dir.glob('puppet/manifests/**/*.pp') +
Dir.glob('puppet/occam/profile/**/*.pp') +
Dir.glob('puppet/occam/role/**/*.pp')

def yamls
  Dir.glob('puppet/hiera/**/*.yaml') + Dir.glob('puppet/hiera/*.yaml')
end

def manifests
  return $base_dirs
end

def manifests_occam
  a = $base_dirs
  f = File.open($include_list)
  f.each do |line|
    if line =~ /^#.*/ or line =~ /^$/
      next
    elsif line =~ /^(.*)$/
      Dir.glob("#{$1}/**/*.pp").each {|l| a << l}
    end
  end
  f.close
  return a
end

def erbs
  return Dir.glob('puppet/occam/profile/templates/**/*.erb')
end

def librarian_files
  return Dir.glob('puppet/apps/*/Puppetfile')
end

def excludes
  h = Hash.new
  f = File.open($ignore_list)
  f.each do |line|
    if line =~ /^#.*/ or line =~ /^$/
      next
    elsif line =~ /(.*?): (.*)$/
      file,args = $1,$2
      if ! h.has_key?(file)
        h[file] = args
      else
        abort("#{file} has duplicated entry in #{ignore_list} file. I quit.")
      end
    end
  end
  f.close
  return h
end
