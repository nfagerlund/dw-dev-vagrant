notify {"sup":}

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
  'libgd-gd2-perl',
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
]

package {$base_packages:
  provider => apt,
  ensure => present,
}

include postfix

# postfix::config { "relay_domains": value  => "localhost host.foo.com" }

class {'apache':
  mpm_module => 'prefork',

}

apache::mod {'apreq2':
  id => apreq_module,
} ->
package {'libapache2-request-perl':
  provider => apt,
  ensure => present,
}
include apache::mod::perl


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
  root_password => 'aoeuhtns',
  package_ensure => present,
  service_enabled => true,
  service_manage => true,

}