# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
begin
  settings = YAML.load(File.read(File.expand_path('./config.yaml')))
  hostname = settings['dw_dev::dw_domain']
  raise unless (hostname.class == String) && (hostname.length > 0)
rescue
  raise "Couldn't get a hostname for the VM! Make sure you have a valid config.yaml file."
end

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "debian/buster64"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  config.vm.network "public_network"
  config.vm.hostname = hostname

  # Install puppet into the base image
  config.vm.provision "shell", inline: "apt-get install --yes puppet"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder "puppet/", "/etc/puppetlabs/code/environments/production", create: true

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true

    # Customize the amount of memory on the VM:
    vb.memory = "2560"
  end

  config.vm.provision "apt", type: "shell" do |s|
    s.inline = <<-EOT
      sudo timedatectl set-timezone UTC
      sudo apt-key adv --recv-keys --keyserver keys.gnupg.net 7F438280EF8D349F
      sudo apt-get update
      sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
    EOT
  end

  config.vm.provision "puppet", run: "always" do |pup|
    pup.environment_path = ["vm", "/etc/puppetlabs/code/environments"]
    pup.environment = "production"
  end

end
