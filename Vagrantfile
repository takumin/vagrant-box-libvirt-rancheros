# vim: set ft=ruby :

require 'json'

# Parse Packer Config
json = JSON.load(File.read(File.join(__dir__, 'packer.json')))

# Vagrant Box Version
version = json['variables']['rancheros_version']

# Require Minimum Vagrant Version
Vagrant.require_version '>= 2.2.4'

# Vagrant Configuration
Vagrant.configure('2') do |config|
  # Require Plugins
  config.vagrant.plugins = ['vagrant-libvirt']

  # RancherOS Box
  config.vm.box = 'takumin/rancheros'
  config.vm.box_url = "file://./vagrant-box-libvirt-rancheros-#{version}.box"

  # Disabled Default Sync
  config.vm.synced_folder '.', '/vagrant', disabled: true

  # Libvirt Provider
  config.vm.provider :libvirt do |libvirt|
    # Memory Size
    libvirt.memory = 1024
    # Random Number Generator
    libvirt.random :model => 'random'
    # Graphic Monitor
    libvirt.graphics_type = 'spice'
    libvirt.graphics_ip = '127.0.0.1'
    libvirt.video_type = 'qxl'
    # Management Network
    libvirt.management_network_mode = 'nat'
    libvirt.management_network_guest_ipv6 = 'no'
  end

  # RancherOS Server
  config.vm.define :rancheros do |domain|
    # Libvirt Provider
    domain.vm.provider :libvirt do |libvirt|
      # Spice Listen Port
      libvirt.graphics_port = 5950
    end
  end
end
