
$dw_domain = 'dev-width.test'
$dw_user = 'dw'
$local_email_domain = 'dw-user-emails.test'
# $dw_user_password = "" # actually, just don't.
$dw_db_user = $dw_user # meh
$dw_db_user_password = 'snthueoa'
$root_db_user_password = 'aoeuhtns'

$ljhome = "/home/${dw_user}/dw"
$developer_github = 'nfagerlund'
$developer_name = 'Nick Fagerlund'
$developer_email = 'nick.fagerlund@gmail.com'


notify {"sup":}

# Hosts, packages, required system services
class {'dw_dev::prerequisites':
  local_email_domain => $local_email_domain,
  dw_domain => $dw_domain,
  root_db_user_password => $root_db_user_password,
}

# ugh I realize this should be an apache::vhost but that type is just too huge
# to get a handle on so I'm gonna cheat
file {'dw-vhost':
  path => '/etc/apache2/sites-available/25-dreamwidth.conf',
  ensure => file,
  mode => '0644',
  content => epp('dw_dev/vhost.epp', {
    'dw_domain' => $dw_domain,
    'dw_user' => $dw_user,
    'ljhome' => $ljhome,
  }),
  require => Package['httpd'],
} ->

file {'dw-vhost-symlink':
  path => '/etc/apache2/sites-enabled/25-dreamwidth.conf',
  target => '/etc/apache2/sites-available/25-dreamwidth.conf',
  ensure => link,
  mode => '0644',
  notify => Class['apache::service'],
}

user {$dw_user:
  ensure => present,
  groups => ['sudo'],
  managehome => true,
  home => "/home/${dw_user}",
  shell => '/bin/bash',
}

# Let me sudo freely so I can restart apache without a second tab open!
file {'/etc/sudoers.d/11_dw':
  ensure => file,
  content => "%dw ALL=(ALL) NOPASSWD: ALL\n",
  mode => '0440',
  owner => 'root',
  group => 'root',
}

# file {$ljhome:
#   ensure => directory,
#   owner => $dw_user,
#   group => $dw_user,
# }

file {'apache_logs':
  ensure => directory,
  path => "/home/${dw_user}/apache_logs",
  owner => $dw_user,
  group => $dw_user,
}

file {'gitconfig':
  ensure => file,
  path => "/home/${dw_user}/.gitconfig",
  content => epp('dw_dev/gitconfig.epp', {
    'developer_name' => $developer_name,
    'developer_email' => $developer_email,
  }),
  owner => $dw_user,
  group => $dw_user,
}

file_line {'g':
  ensure => present,
  path => "/home/${dw_user}/.profile",
  line => "alias g='git'",
}

file_line {'ljhome':
  ensure => present,
  path => "/home/${dw_user}/.profile",
  line => "export LJHOME=${ljhome}",
  match => '^export LJHOME',
  replace_all_matches_not_matching_line => true,
}

Vcsrepo {
  require => Package['git'],
}

vcsrepo {'dw-free':
  path => $ljhome,
  ensure => present,
  owner => $dw_user,
  group => $dw_user,
  provider => git,
  branch => 'develop',
  remote => $developer_github,
  source => {
    $developer_github => "https://github.com/${developer_github}/dw-free.git",
    upstream => 'https://github.com/dreamwidth/dw-free.git',
  },
}

vcsrepo {'dw-nonfree':
  path => "${ljhome}/ext/dw-nonfree",
  ensure => present,
  owner => $dw_user,
  group => $dw_user,
  require => Vcsrepo['dw-free'],
  provider => git,
  branch => 'develop',
  remote => $developer_github,
  source => {
    $developer_github => "https://github.com/${developer_github}/dw-nonfree.git",
    upstream => 'https://github.com/dreamwidth/dw-nonfree.git',
  },
}

# A bunch of directories under ljhome/ext/local
$ext_local_dirs = [
  "${ljhome}/ext/local",
  "${ljhome}/ext/local/etc",
  "${ljhome}/ext/local/htdocs",
  "${ljhome}/ext/local/htdocs/inc",
]

file {$ext_local_dirs:
  ensure => directory,
  require => Vcsrepo['dw-free'],
  owner => $dw_user,
  group => $dw_user,
}

file {'ext-local-scope':
  path => "${ljhome}/ext/local/.dir_scope",
  ensure => file,
  content => "highest\n",
  owner => $dw_user,
  group => $dw_user,
}

file {'config-local.pl':
  path => "${ljhome}/ext/local/etc/config-local.pl",
  ensure => file,
  content => epp('dw_dev/config-local.epp', {'developer' => $developer_github}),
  owner => $dw_user,
  group => $dw_user,
}

file {'config-private.pl':
  path => "${ljhome}/ext/local/etc/config-private.pl",
  ensure => file,
  content => epp('dw_dev/config-private.epp', {
    'dw_domain' => $dw_domain,
    'dw_db_user' => $dw_db_user,
    'dw_db_user_password' => $dw_db_user_password,
  }),
  owner => $dw_user,
  group => $dw_user,
  mode => '0600',
}

file {'allowed-email-tlds':
  path => "${ljhome}/ext/local/htdocs/inc/tlds",
  ensure => file,
  content => file('dw_dev/tlds'),
  owner => $dw_user,
  group => $dw_user,
}

mysql::db {'dw':
  user => $dw_db_user,
  password => $dw_db_user_password,
  host => 'localhost',
  grant => 'ALL',
}
mysql::db {'dw_schwartz':
  user => $dw_db_user,
  password => $dw_db_user_password,
  host => 'localhost',
  grant => 'ALL',
}

