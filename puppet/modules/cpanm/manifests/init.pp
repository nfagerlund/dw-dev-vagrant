# Class: cpanm
# ===========================
#
# Full description of class cpanm here.
#
# Parameters
# ----------
#
# * `mirror`
# A CPAN mirror to use to retrieve App::cpanminus. This is passed to
# `cpanm` as `--from`, meaning that only this mirror will be used.
#
# Examples
# --------
#
# @example
#    include cpanm
#
# @example
#    class {'cpanm':
#      mirror =>  'http://mirror.my.org/cpan/',
#    }
#
# Authors
# -------
#
# James McDonald <james@jamesmcdonald.com>
#
# Copyright
# ---------
#
# Copyright 2016-2017 James McDonald, unless otherwise noted.
#
class cpanm (
  $mirror = undef,
){
  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease in ['6','7'] {
    $packages = ['perl', 'make', 'gcc', 'perl-core']
  } else {
    $packages = ['perl', 'make', 'gcc']
  }

  package {$packages:
    ensure => present,
  }

  file {'/var/cache/cpanm-install':
    ensure => file,
    source => 'puppet:///modules/cpanm/cpanm',
  }

  $from = $mirror ? {
    undef   => '',
    default => "--from ${mirror}",
  }
  exec {"/usr/bin/perl /var/cache/cpanm-install ${from} -n App::cpanminus":
    unless  => '/usr/bin/test -x /usr/bin/cpanm -o -x /usr/local/bin/cpanm',
    require => [File['/var/cache/cpanm-install'], Package['perl', 'gcc']],
  }
}
