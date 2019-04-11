# Responsible for:
# - /etc/hosts changes
# - packages
# - classes that configure required services (postfix, apache, mysql server, gearman) and their plugins
# - NOT any app configs.
class dw_dev::prerequisites (
  String $local_email_domain,
  String $dw_domain,
  String $root_db_user_password,
) {
  # DW can't send emails to its own official hostname, so make an alias.
  host {$local_email_domain:
    ip => '127.0.0.1',
  }

  $base_packages = [
    'git',
  #   'apache2',      # several packages handled by their own classes:
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
    # make sure that local email alias works.
    mydestination => "${dw_domain}, ${local_email_domain}, localhost, localhost.localdomain",
  }

  # postfix::config { "relay_domains": value  => "localhost host.foo.com" }

  class {'apache':
    mpm_module => 'prefork',
    default_vhost => false,
  }

  apache::mod {'apreq2':
    # special snowflake, needs non-matching name in configs.
    id => apreq_module,
  } ->
  package {'libapache2-request-perl':
    provider => apt,
    ensure => present,
  }
  include apache::mod::perl

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


  class {'cpan':
    manage_config  => true,
    manage_package => false,
  #   installdirs    => 'site',
  #   local_lib      => false,
    config_hash    => {
      'build_requires_install_policy' => 'no', # WHO KNOWS, but it's the default.
      'trust_test_report_history' => '1',
    },
  }

  Cpan {
    ensure => present,
    force => false,
    require => Class['cpan'],
  }

  $cpan_modules = [
    # Bundle::CPAN stuff, unbundled:
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

  cpan {$cpan_modules:}

}
