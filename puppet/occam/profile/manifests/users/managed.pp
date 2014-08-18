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
# == Define: profile::users::managed
#
# Manages user accounts.
#
# === Parameters
# [username]
#   Name of an account.
#
# [repo]
#   What repo to clone in home dir (optional)
#
# [runcoms]
#   no idea
#
# [sudo]
#   sudo line (optional)
#
# [uid]
#   Specyfy uid (optional)
#
# [shell]
#   self-explanatory (optional)
#
# [home]
#   self-explanatory (optional)
#
# [ssh_key_type]
#   self-explanatory (optional)
#
# [ensure]
#   present/absent
#
# [ssh_key]
#  self-explanatory
#
# [groups]
#   What groups should user be added to
#
# === Authors
#
# James Kyle <james@jameskyle.org>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
define profile::users::managed (
  $username     = $title,
  $repo         = undef,
  $runcoms      = undef,
  $sudo         = undef,
  $uid          = undef,
  $shell        = '/bin/bash',
  $home         = "/home/${username}",
  $ssh_key_type = 'ssh-rsa',
  $ensure       = present,
  $ssh_key      = undef,
  $groups       = [],
) {
  include sudo

  if $shell == 'zsh' {
    case $::osfamily {
      'Debian': {$shell_path = '/usr/bin/zsh'}
      'RedHat': {$shell_path = '/bin/zsh'    }
      default:  {$shell_path = $shell}
    }
  }
  elsif $shell == 'bash' {
    $shell_path = '/bin/bash'
  }
  else {
    $shell_path = $shell
  }

  # FIXME:: Passing 'absent' to ensure in hiera does not delete
  #         the user account
  account {$username:
    ensure       => $ensure,
    ssh_key      => $ssh_key,
    ssh_key_type => $ssh_key_type,
    shell        => $shell_path,
    groups       => $groups,
    uid          => $uid,
    home_dir     => $home,
  }

  if $sudo != undef {
    sudo::conf {$username:
      content =>  $sudo[content],
      require => Account[$username],
    }
  }

  if $repo != undef {
    case $::osfamily {
      'Debian': { $git_package = 'git-core' }
      'RedHat': { $git_package = 'git'      }
      default:  { $git_package = 'git'      }
    }

    if ! defined(Package[$git_package]) { package {$git_package: }}

    vcsrepo {"${home}/${repo['target']}":
      ensure   => $ensure,
      provider => git,
      source   => $repo['source'],
      revision => $repo['revision'],
      owner    => $username,
      group    => $username,
      require  => [Account[$username], Package[$git_package]],
    }
  }

  if $ensure == present {
    $runcom_defaults = {'ensure' =>  link }
  } else {
    $runcom_defaults = {'ensure' => $ensure }
  }

  if $runcoms != undef {
    create_resources('profile::users::runcom', $runcoms, $runcom_defaults)
    Account[$username] -> Profile::Users::Runcom <| |>
  }

  Group<| tag == user_groups |>
}
