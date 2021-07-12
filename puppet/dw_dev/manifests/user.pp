# Responsible for DW's OS user, and the stuff that makes it less awful to be
# logged in as them.
class dw_dev::user (
  String $dw_user = 'dw',
  String $developer_name = 'Onion Knight',
  String $developer_email = 'unconfigured@example.com',
  String $ljhome = "/home/dw/dw",
){

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
    content => "%${dw_user} ALL=(ALL) NOPASSWD: ALL\n",
    mode => '0440',
    owner => 'root',
    group => 'root',
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
    replace => false,
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

}
