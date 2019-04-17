# vim: set ft=ruby :

# Require Minimum Vagrant Version
Vagrant.require_version '>= 2.2.4'

# Vagrant Configuration
Vagrant.configure('2') do |config|
  # Require Plugins
  config.vagrant.plugins = ['vagrant-libvirt']

  # RancherOS Box
  config.vm.box = 'rancheros'

  # Disabled Default Sync
  config.vm.synced_folder '.', '/vagrant', disabled: true

  # Libvirt Provider Configuration
  config.vm.provider :libvirt do |libvirt|
    # Memory
    libvirt.memory = 1024
    # Monitor
    libvirt.graphics_type = 'spice'
    libvirt.graphics_ip = '127.0.0.1'
    libvirt.video_type = 'qxl'
    # Network
    libvirt.management_network_mode = 'nat'
    libvirt.management_network_guest_ipv6 = 'no'
  end

  # RancherOS Server
  config.vm.define :rancheros do |domain|
    # Libvirt Provider Configuration
    domain.vm.provider :libvirt do |libvirt|
      # Monitor
      libvirt.graphics_port = 5950
    end
  end
end
