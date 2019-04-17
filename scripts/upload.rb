#!/usr/bin/env ruby

USERNAME = 'takumin'
REPONAME = 'rancheros'
PROVIDER = 'libvirt'
ENDPOINT = 'https://app.vagrantup.com'

unless ENV['VAGRANT_CLOUD_TOKEN']
  raise ArgumentError, "Require Environment Variable: VAGRANT_CLOUD_TOKEN"
end

unless ENV['RANCHEROS_VERSION']
  raise ArgumentError, "Require Environment Variable: RANCHEROS_VERSION"
end

require "http"

api = HTTP.persistent(ENDPOINT).headers(
  "Content-Type" => "application/json",
  "Authorization" => "Bearer #{ENV['VAGRANT_CLOUD_TOKEN']}"
)

# Create a new box
api.post "/api/v1/boxes",
  json: { box: { username: USERNAME, name: REPONAME } }

# Create a new version
api.post "/api/v1/box/#{USERNAME}/#{REPONAME}/versions",
  json: { version: { version: "#{ENV['RANCHEROS_VERSION']}" } }

# Create a new provider
api.post "/api/v1/box/#{USERNAME}/#{REPONAME}/version/#{ENV['RANCHEROS_VERSION']}/providers",
  json: { provider: { name: PROVIDER } }

# Prepare the provider for upload
response = api.get("/api/v1/box/#{USERNAME}/#{REPONAME}/version/#{ENV['RANCHEROS_VERSION']}/provider/libvirt/upload")

# Extract the upload URL
upload_path = response.parse['upload_path']

# Upload the box image
HTTP.put upload_path, body: File.open("vagrant-box-libvirt-rancheros-#{ENV['RANCHEROS_VERSION']}.box")

# Release the version
api.put("/api/v1/box/#{USERNAME}/#{REPONAME}/version/#{ENV['RANCHEROS_VERSION']}/release")
