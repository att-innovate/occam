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
module Puppet::Parser::Functions
  newfunction(:galera_nextserver, :type => :rvalue, :doc => <<-EOS
    Returns ip of the next server in galera cluster.
    EOS
  ) do |args|

    if args.size != 2
      raise(Puppet::ParseError,
      "galera_nextserver(): Wrong number of arguments " +
      "given (#{args.size} of 2 required)")
    end
    if args[1].class != Array
      raise(Puppet::ParseError,
      "galera_nextserver(): second argument is required to be an array!")
    end

    req,controllers = args[0],args[1]
    if (controllers.length != 0) and (controllers.include? req)

      require 'digest'

      a = []
      h = {}
      controllers.each {|v| h[Digest::SHA1.hexdigest(v).to_i(16)] = v }

      h.each {|k,v| a << k }
      a.sort
      i = a.index(h.index(req))
      retval = ''
      if i != a.length - 1
        retval = h[a[i+1]]
      else
        retval = h[a[0]]
      end
      if retval != req
        return retval
      else
        return nil
      end
    else
      return nil
    end
  end
end
