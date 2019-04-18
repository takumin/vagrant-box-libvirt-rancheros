#!/usr/bin/env ruby

require 'net/https'
require 'json'
require 'uri'
require 'pp'

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

unless ENV['VAGRANT_BOX_FILENAME']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_FILENAME'
end

if ENV['HTTPS_PROXY'] || ENV['https_proxy'] || ENV['HTTP_PROXY'] || ENV['http_proxy']
  proxy = URI.parse(ENV['HTTPS_PROXY'] || ENV['https_proxy'] || ENV['HTTP_PROXY'] || ENV['http_proxy'])
else
  proxy = URI::Generic.new(nil, nil, nil, nil, nil, nil, nil, nil, nil)
end

username   = ENV['VAGRANT_CLOUD_USER']
repository = ENV['VAGRANT_CLOUD_REPO']
provider   = ENV['VAGRANT_BOX_PROVIDER']
version    = ENV['VAGRANT_BOX_VERSION']
filename   = ENV['VAGRANT_BOX_FILENAME']

upload = URI::Generic.new(nil, nil, nil, nil, nil, nil, nil, nil, nil)

endpoint = URI.parse('https://app.vagrantup.com')

header = {
  'Content-Type'  => 'application/json',
  'Accept'        => 'application/json',
  'Authorization' => "Bearer #{ENV['VAGRANT_CLOUD_TOKEN']}",
}

https = Net::HTTP.new(
  endpoint.host,
  endpoint.port,
  proxy.host,
  proxy.port,
  proxy.user,
  proxy.password
)

https.use_ssl = true
https.ca_path = '/etc/ssl/certs'
https.verify_mode = OpenSSL::SSL::VERIFY_PEER

https.start do
  # Create Box
  res = https.post("/api/v1/boxes", {
    'box' => {
      'username'   => username,
      'name'       => repository,
      'is_private' => false,
    },
  }.to_json, header)

  # Logger
  case res
  when Net::HTTPSuccess
    puts "Create Box"
  when Net::HTTPUnprocessableEntity
    puts "Exists Box"
  end

  # Create Version
  res = https.post("/api/v1/box/#{username}/#{repository}/versions", {
    'version' => {
      'version' => version,
    },
  }.to_json, header)

  # Logger
  case res
  when Net::HTTPSuccess
    puts "Create Version"
  when Net::HTTPUnprocessableEntity
    puts "Exists Version"
  end

  # Create Provider
  res = https.post("/api/v1/box/#{username}/#{repository}/version/#{version}/providers", {
    'provider' => {
      'name' => provider,
    },
  }.to_json, header)

  # Logger
  case res
  when Net::HTTPSuccess
    puts "Create Provider"
  when Net::HTTPUnprocessableEntity
    puts "Exists Provider"
  end

  # Get Upload URL
  res = https.get("/api/v1/box/#{username}/#{repository}/version/#{version}/provider/#{provider}/upload", header)

  # Logger
  case res
  when Net::HTTPSuccess
    puts "Get Upload Uri"
  else
  end

  # Upload Uri
  upload = URI.parse(JSON.parse(res.body)['upload_path'])

  # Close Connection
  https.finish
end

https = Net::HTTP.new(
  upload.host,
  upload.port,
  proxy.host,
  proxy.port,
  proxy.user,
  proxy.password
)

https.use_ssl = true
https.ca_path = '/etc/ssl/certs'
https.verify_mode = OpenSSL::SSL::VERIFY_PEER

https.start do
  req = Net::HTTP::Post.new(upload.path)

  File.open(filename) do |file|
    req.body_stream = file

    # req['Content-Length'] = file.lstat.size.to_s
    req['Transfer-Encoding'] = 'chunked'

    res = https.request(req)
  end

  # Close Connection
  https.finish
end
