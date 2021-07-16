class dw_dev::test (
  String $dw_user = 'dw',
  String $ljhome = '/home/dw/dw',
  String $dw_db_user = 'dw',
  String $dw_db_user_password,
){

  file {"${ljhome}/ext/local/t":
    ensure => directory,
    owner => $dw_user,
    group => $dw_user,
  }
  
  file {'config-test-private.pl':
    path => "${ljhome}/ext/local/t/config-test-private.pl",
    ensure => file,
    content => epp('dw_dev/config-test-private.epp', {
	'dw_db_user' => $dw_db_user,
	'dw_db_user_password' => $dw_db_user_password,
      }),
    owner => $dw_user,
    group => $dw_user,
    replace => true,
  }

  file {'config-test.pl':
    path => "${ljhome}/ext/local/t/config-test.pl",
    ensure => file,
    content => epp('dw_dev/config-test.epp', {}),
    owner => $dw_user,
    group => $dw_user,
    replace => true,
  }

  file {'populate-test-db':
    path => "${ljhome}/ext/local/t/populate-test-db",
    ensure => file,
    content => epp('dw_dev/populate-test-db.epp', {}),
    owner => $dw_user,
    group => $dw_user,
    replace => true,
    mode => '0755',
    require => Vcsrepo['dw-free'],
  }

  ## Test databases:
  mysql::db {'test_master':
    user => $dw_db_user,
    password => $dw_db_user_password,
    host => 'localhost',
    grant => 'ALL',
  }
  mysql::db {'test_schwartz':
    user => $dw_db_user,
    password => $dw_db_user_password,
    host => 'localhost',
    grant => 'ALL',
  }
  
  exec {
    default:
      environment => ["LJHOME=${ljhome}", "DW_TEST=1"],
      cwd => $ljhome,
      user => $dw_user,
      logoutput => true,
    ;

    'populate-test-db':
      command => "${ljhome}/ext/local/t/populate-test-db",
      refreshonly => true,
      subscribe => [
        Mysql::Db['test_master'],
        Mysql::Db['test_schwartz'],
        File['populate-test-db'],
      ],
    ;

    # This follows the flow of t/bin/initialize-db and should ideally replace
    # the populate-test-db shellscript above.
    #
    # 'update-test-db once':
    #   command => "${ljhome}/bin/upgrading/update-db.pl -r --innodb",
    #   refreshonly => true,
    #   subscribe => [
    #     Mysql::Db['test_master'],
    #     Mysql::Db['test_schwartz'],
    #     File['config-test.pl'],
    #     File['config-test-private.pl'],
    #   ],
    # ;
    # 'update-test-db twice':
    #   command => "${ljhome}/bin/upgrading/update-db.pl -r --innodb",
    #   refreshonly => true,
    #   subscribe => Exec['update-test-db once'],
    # ;
    # 'update-cluster once':
    #   command => "${ljhome}/bin/upgrading/update-db.pl -r --cluster=all --innodb",
    #   refreshonly => true,
    #   subscribe => Exec['update-test-db twice'],
    # ;
    # 'update-cluster twice':
    #   command => "${ljhome}/bin/upgrading/update-db.pl -r --cluster=all --innodb",
    #   refreshonly => true,
    #   subscribe => Exec['update-cluster once'],
    # ;
    # 'texttool':
    #   command => "${ljhome}/bin/upgrading/texttool.pl load",
    #   refreshonly => true,
    #   subscribe => Vcsrepo['dw-free'], # only needs to run on code updates.
    #   # if you're handling code updates yourself, you're in charge of this.
    # ;
  }
}
