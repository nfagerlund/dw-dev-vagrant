class dw_dev (
  String $dw_domain = 'dev-width.test',
  String $dw_user = 'dw',
  String $local_email_domain = 'dev-width.post',
  String $dw_db_user = "dw",
  String $dw_db_user_password,
  String $root_db_user_password,
  String $dw_app_system_user_password,
  String $ljhome = "/home/dw/dw",
  String $developer_github,
  String $developer_name = 'Onion Knight',
  String $developer_email = 'unconfigured@example.com',
  Optional[String] $dw_free_revision = undef,
) {

  # Hosts, packages, required system services
  class {'dw_dev::prerequisites':
    local_email_domain => $local_email_domain,
    dw_domain => $dw_domain,
    root_db_user_password => $root_db_user_password,
  }

  # the OS user that the app relies on
  class {'dw_dev::user':
    dw_user => $dw_user,
    developer_name => $developer_name,
    developer_email => $developer_email,
    ljhome => $ljhome,
  }

  class {'dw_dev::app':
    require => [
      Class['dw_dev::prerequisites'],
      Class['dw_dev::user'],
    ],
    dw_domain => $dw_domain,
    dw_user => $dw_user,
    ljhome => $ljhome,
    developer_github => $developer_github,
    dw_db_user => $dw_db_user,
    dw_db_user_password => $dw_db_user_password,
    dw_app_system_user_password => $dw_app_system_user_password,
    dw_free_revision => $dw_free_revision,
  }

  ## The worker manager service:

  service {'dw-worker-manager':
    provider => base,
    ensure => running,
    start => "runuser -l dw -c 'LJHOME=${ljhome} ${ljhome}/bin/worker-manager'",
    pattern => "worker-manager", # allows stop/status/restart
  }


}
