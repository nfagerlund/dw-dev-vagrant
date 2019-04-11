
$dw_domain = 'dev-width.test'
$dw_user = 'dw'
$local_email_domain = 'dw-user-emails.test'
$dw_db_user = $dw_user # meh
$dw_db_user_password = 'snthueoa'
$root_db_user_password = 'aoeuhtns'
$dw_app_system_user_password = 'uhetonas9'

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
}


file {'allowed-email-tlds':
  path => "${ljhome}/ext/local/htdocs/inc/tlds",
  ensure => file,
  content => file('dw_dev/tlds'),
  owner => $dw_user,
  group => $dw_user,
}


