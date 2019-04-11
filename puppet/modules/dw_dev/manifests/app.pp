class dw_dev::app (
  String $dw_domain,
  String $dw_user = 'dw',
  String $ljhome = '/home/dw/dw',
  String $developer_github,
  String $dw_db_user = 'dw',
  String $dw_db_user_password,
  String $dw_app_system_user_password,
){

  ## Apache configs:

  # TBH *any* change in this class means Apache needs a restart.
  Class[$name] ~> Class['apache::service']
  # Now, I *think* the service class is free-floating and not contained in the
  # base apache class. But just in case, maybe avoid forming any 'require'
  # relationships with Class['apache'] -- the title of Package['httpd'] is
  # normalized, so you can just require that instead.

  file {'apache_logs':
    ensure => directory,
    path => "/home/${dw_user}/apache_logs",
    owner => $dw_user,
    group => $dw_user,
    before => File['dw-vhost'],
  }

  # ugh I realize this should be an apache::vhost but that type is just too
  # huge to get a handle on so I'm gonna cheat
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
    notify => Class['apache::service'],
  }

  file {'dw-vhost-symlink':
    path => '/etc/apache2/sites-enabled/25-dreamwidth.conf',
    target => '/etc/apache2/sites-available/25-dreamwidth.conf',
    ensure => link,
    mode => '0644',
    require => Package['httpd'],
    notify => Class['apache::service'],
  }

  ## Application code:

  vcsrepo {'dw-free':
    path => $ljhome,
    ensure => present,
    owner => $dw_user,
    group => $dw_user,
    provider => git,
    branch => 'develop',
    remote => $developer_github,
    source => {
      # abjure 'origin' for it is unclean. I have spoken. :|
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

  ## App config overrides:

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
  file {'config-override-scope':
    path => "${ljhome}/ext/local/.dir_scope",
    ensure => file,
    content => "highest\n",
    owner => $dw_user,
    group => $dw_user,
  }

  # The actual config files. I recommend editing the templates when you need to
  # change settings, so they'll survive across restarts and the occasional total
  # dev environment wipe.
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


  ## App databases:
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

  ## Come up w/ a name for this stuff later:
  if false { # DEFINITELY need to test this on a fresh install before enabling
    exec {
      default:
        environment => ["LJHOME=${ljhome}"],
        cwd => $ljhome,
        user => $dw_user,
        logoutput => true,
      ;
      'checkconfig.pl':
        command => "${ljhome}/bin/checkconfig.pl",
        refreshonly => true,
        # (also gets notified by anything notifying this class.)
        subscribe => [
          File['config-local.pl'],
          File['config-private.pl'],
          Mysql::Db['dw'],
        ],
      ;
      'update-db once':
        command => "${ljhome}/bin/upgrading/update-db.pl -r --innodb",
        refreshonly => true,
        subscribe => [
          File['config-local.pl'],
          File['config-private.pl'],
          Mysql::Db['dw'],
        ],
      ;
      'update-db twice':
        command => "${ljhome}/bin/upgrading/update-db.pl -r --innodb",
        refreshonly => true,
        subscribe => [
          Exec['update-db once'],
        ],
      ;
      'im-in-love-with-rock-n-roll':
        command => "${ljhome}/bin/upgrading/update-db.pl -r --innodb",
        refreshonly => true,
        subscribe => [
          Exec['update-db twice'],
        ],
      ;
      'populate-app-db':
        command => "#{ljhome}/bin/upgrading/update-db.pl -p",
        onlyif => '/bin/false', # needs more testing.
      ;
      'populate-schwartz-db':
        command => "/usr/bin/mysql -u ${dw_db_user} -p${dw_db_user_password} dw_schwartz < /usr/share/doc/libtheschwartz-perl/schema.sql",
        onlyif => '/bin/false', # needs more testing
      ;
      'make_system.pl': # creates system user in dw app
        provider => shell,
        command => "echo '${dw_app_system_user_password}' | ${ljhome}/bin/upgrading/make_system.pl",
        onlyif => '/bin/false', # needs more testing
      ;
      'texttool.pl':
        command => "${ljhome}/bin/upgrading/texttool.pl load",
        refreshonly => true,
        subscribe => [
          Vcsrepo['dw-free'],
        ],
      ;
      'build-static.sh':
        command => "${ljhome}/bin/build-static.sh",
        # just always run it.
      ;
    }
  }
}
