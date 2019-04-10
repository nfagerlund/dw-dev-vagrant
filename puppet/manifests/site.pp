
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

# DW can't send emails to its own official hostname, so make an alias.
host {$local_email_domain:
  ip => '127.0.0.1',
}

$base_packages = [
  'git',
#   'apache2',
#   'apache2-bin',
#   'apache2-data',
#   'apache2-utils',
#   'libapache2-mod-perl2',
#   'libapache2-mod-apreq2',
#   'libapache2-request-perl',
#   'mysql-server',
  'wget',
  'unzip',
  'links',
  'vim',
  'libclass-autouse-perl',
  'libdatetime-perl',
  'libcache-memcached-perl',
  'libhash-multivalue-perl',
  # 'libgd-gd2-perl', # virtual package, provided by the next one:
  'libgd-perl',
  'libhtml-template-perl',
  'libwww-perl',
  'libmime-lite-perl',
  'liburi-perl',
  'libxml-simple-perl',
  'libclass-accessor-perl',
  'libclass-data-inheritable-perl',
  'libclass-trigger-perl',
  'libcrypt-dh-perl',
  'libmath-bigint-gmp-perl',
  'liburi-fetch-perl',
  'libgd-graph-perl',
  'libgnupg-interface-perl',
  'libmail-gnupg-perl',
  'perlmagick',
  'libproc-processtable-perl',
  'libsoap-lite-perl',
  'librpc-xml-perl',
  'libstring-crc32-perl',
  'libtext-vcard-perl',
  'libxml-atom-perl',
  'libxml-rss-perl',
  'libimage-size-perl',
  'libunicode-maputf8-perl',
  'libgtop2-dev',
  'build-essential',
  'libnet-openid-consumer-perl',
  'libnet-openid-server-perl',
  'libyaml-perl',
  'libcaptcha-recaptcha-perl',
  'libdbd-sqlite3-perl',
  'libtest-simple-perl',
  'libtemplate-perl',
  'libterm-readkey-perl',
  'libmime-base64-urlsafe-perl',
  'gcc',
  'libtest-most-perl',
  'libgearman-client-perl',
  'libfile-find-rule-perl',
  'libbusiness-creditcard-perl',
  'liblwpx-paranoidagent-perl',
  'libtheschwartz-perl',
  'libfile-type-perl',
  'libjson-perl',
  'ruby',
  'libdbd-mysql-perl',
  'libdanga-socket-perl',
  'libio-aio-perl',
  'libsys-syscall-perl',
  'liblog-log4perl-perl',
  'libtext-markdown-perl',
  'libimage-exiftool-perl',
  'libnet-oauth-perl',
  'libnet-smtps-perl',
  'libxmlrpc-lite-perl',
  'default-jre',
  'gearman-server',
  'silversearcher-ag',
]

package {$base_packages:
  provider => apt,
  ensure => present,
}

package {'sass':
  provider => gem,
  ensure => '3.2.19',
}

package {'compass':
  provider => gem,
  ensure => '0.12.2',
}

service {'gearman-server':
  ensure => running,
  enable => true,
  require => Package['gearman-server'],
  hasrestart => true,
}

class {'postfix':
  mydestination => "${dw_domain}, ${local_email_domain}, localhost, localhost.localdomain",
}

# postfix::config { "relay_domains": value  => "localhost host.foo.com" }

class {'apache':
  mpm_module => 'prefork',
  default_vhost => false,

}

apache::mod {'apreq2':
  id => apreq_module,
} ->
package {'libapache2-request-perl':
  provider => apt,
  ensure => present,
}
include apache::mod::perl

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
  notify => Class['::apache::service'],
}

class {'cpan':
  manage_config  => true,
  manage_package => false,
#   installdirs    => 'site',
#   local_lib      => false,
  config_hash    => {
    'build_requires_install_policy' => 'no',
    'trust_test_report_history' => '1',
  },
}

Cpan {
  ensure => present,
  force => false,
  require => Class['cpan'],
}

$cpan_packgaes = [
  # Bundle::CPAN stuff:
  'ExtUtils::MakeMaker',
  'Test::Harness',
  'CPAN::Meta::Requirements',
  'ExtUtils::CBuilder',
  'File::Temp',
  'Test::More',
  'Data::Dumper',
  'IO::Compress::Base',
  'Compress::Zlib',
  'IO::Zlib',
  'Archive::Tar',
  'Module::Build',
  'File::Spec',
  'Digest::SHA',
  'File::HomeDir',
  'Archive::Zip',
  'Net::FTP',
  'Term::ReadKey',
#  'Term::ReadLine::Perl', # the one really problematic one
  'YAML',
  'Parse::CPAN::Meta',
  'Text::Glob',
  'CPAN',
  'File::Which',
  # Other stuff:
  'GTop',
  'Digest::SHA1',
  'Unicode::CheckUTF8',
  'MogileFS::Client',
  'TheSchwartz::Worker::SendEmail',
  'LWP::UserAgent::Paranoid',
  'Mozilla::CA',
  'List::Util',
  'Paws::S3',
  'Net::DNS',
  'Text::Fuzzy',
]

# wow, this seems impossible to install noninteractively:
# - 'Term::ReadLine::Perl' does something super-fucky during installation and just piping `yes` to it sends it into an infinite loop.
# - It's a bundle, not a module! So when the cpan provider tries to run `perl #{ll} -M#{resource[:name]} -e1 > /dev/null 2>&1`, it returns 2 and blows up. Even though it's installed.
# so, can we do it as an exec? got to find the exact sequence of things to echo to the command?

# cpan {'Bundle::CPAN':} ->

cpan {$cpan_packgaes:}

class {'mysql::server':
  root_password => $root_db_user_password,
  package_ensure => present,
  service_enabled => true,
  service_manage => true,
  override_options => {
    mysqld => {
      sql_mode => "''",
    }
  }
}

user {$dw_user:
  ensure => present,
  groups => ['sudo'],
  managehome => true,
  home => "/home/${dw_user}",
  shell => '/bin/bash',
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
  revision => 'develop',
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
  revision => 'develop',
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

