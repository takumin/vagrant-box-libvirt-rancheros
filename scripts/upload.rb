#!/usr/bin/env ruby

unless ENV['VAGRANT_CLOUD_USER']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_CLOUD_USER'
end

unless ENV['VAGRANT_CLOUD_REPO']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_CLOUD_REPO'
end

unless ENV['VAGRANT_CLOUD_TOKEN']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_CLOUD_TOKEN'
end

unless ENV['VAGRANT_BOX_PROVIDER']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_PROVIDER'
end

unless ENV['VAGRANT_BOX_VERSION']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_VERSION'
end
