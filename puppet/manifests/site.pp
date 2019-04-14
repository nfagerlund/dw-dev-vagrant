include "dw_dev"

$my_ips = $facts['networking']['interfaces'].map |$name, $interface| {
  $interface['ip']
}.join(', ')
notify {'networking msg':
  message => "Make sure to set up DNS so this machine's domain name (and all its subdomains) resolve to its bridged IP address.\n  Hostname: ${facts['fqdn']}\n  IP addresses: ${my_ips}.",
  require => Class['dw_dev'],
}
