#!/usr/bin/env ruby

require 'net/https'
require 'json'
require 'uri'

class Integer
  def to_filesize
    {
      'B'   => 1024,
      'KiB' => 1024 * 1024,
      'MiB' => 1024 * 1024 * 1024,
      'GiB' => 1024 * 1024 * 1024 * 1024,
      'TiB' => 1024 * 1024 * 1024 * 1024 * 1024
    }.each_pair { |e, s| return "#{(self.to_f / (s / 1024)).round(2)}#{e}" if self < s }
  end
end

class Net::HTTP::Upload
  attr_reader :size

  def initialize(req, &block)
    @req = req
    @callback = block
    @size = 0
    if req.body_stream
      @io = req.body_stream
      req.body_stream = self
    else
      raise NotImplementedError
    end
  end

  def readpartial(maxlen, outbuf)
    begin
      str = @io.readpartial(maxlen, outbuf)
    ensure
      @callback.call(self) unless @size.zero?
    end
    @size += str.length
    str
  end
end

unless ENV['VAGRANT_CLOUD_USER']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_CLOUD_USER'
end

unless ENV['VAGRANT_CLOUD_REPO']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_CLOUD_REPO'
end

unless ENV['VAGRANT_CLOUD_TOKEN']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_CLOUD_TOKEN'
end

unless ENV['VAGRANT_BOX_NAME']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_NAME'
end

unless ENV['VAGRANT_BOX_SHORT']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_SHORT'
end

unless ENV['VAGRANT_BOX_DESCRIPTION']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_DESCRIPTION'
end

unless ENV['VAGRANT_BOX_TIMESTAMP']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_TIMESTAMP'
end

unless ENV['VAGRANT_BOX_BUILD']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_BUILD'
end

unless ENV['VAGRANT_BOX_VERSION']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_VERSION'
end

unless ENV['VAGRANT_BOX_PROVIDER']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_PROVIDER'
end

unless ENV['VAGRANT_BOX_FILENAME']
  raise ArgumentError, 'Require Environment Variable: VAGRANT_BOX_FILENAME'
end

if ENV['HTTPS_PROXY'] || ENV['https_proxy'] || ENV['HTTP_PROXY'] || ENV['http_proxy']
  proxy = URI.parse(ENV['HTTPS_PROXY'] || ENV['https_proxy'] || ENV['HTTP_PROXY'] || ENV['http_proxy'])
else
  proxy = URI::Generic.new(nil, nil, nil, nil, nil, nil, nil, nil, nil)
end

username    = ENV['VAGRANT_CLOUD_USER']
repository  = ENV['VAGRANT_CLOUD_REPO']
boxname     = ENV['VAGRANT_BOX_NAME']
short       = ENV['VAGRANT_BOX_SHORT']
description = ENV['VAGRANT_BOX_DESCRIPTION']
timestamp   = ENV['VAGRANT_BOX_TIMESTAMP']
buildtime   = ENV['VAGRANT_BOX_BUILD']
version     = ENV['VAGRANT_BOX_VERSION']
release     = "#{version}.#{timestamp}"
provider    = ENV['VAGRANT_BOX_PROVIDER']
filename    = ENV['VAGRANT_BOX_FILENAME']

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
      'username'          => username,
      'name'              => repository,
      'short_description' => short,
      'description'       => description,
      'is_private'        => false,
    },
  }.to_json, header)

  # Logger
  case res
  when Net::HTTPSuccess
    puts "Create Box: #{username}/#{repository}"
  when Net::HTTPUnprocessableEntity
    puts "Exists Box: #{username}/#{repository}"
  end

  # Create Version
  res = https.post("/api/v1/box/#{username}/#{repository}/versions", {
    'version' => {
      'version'     => release,
      'description' => "- #{boxname}\n- Version #{version}\n- Build #{buildtime}\n- #{description}",
    },
  }.to_json, header)

  # Logger
  case res
  when Net::HTTPSuccess
    puts "Create Version: #{release}"
  when Net::HTTPUnprocessableEntity
    puts "Exists Version: #{release}"
  end

  # Create Provider
  res = https.post("/api/v1/box/#{username}/#{repository}/version/#{release}/providers", {
    'provider' => {
      'name' => provider,
    },
  }.to_json, header)

  # Logger
  case res
  when Net::HTTPSuccess
    puts "Create Provider: #{provider}"
  when Net::HTTPUnprocessableEntity
    puts "Exists Provider: #{provider}"
  end

  # Get Upload URL
  res = https.get("/api/v1/box/#{username}/#{repository}/version/#{release}/provider/#{provider}/upload", header)

  # Logger
  case res
  when Net::HTTPSuccess
    puts "Get Upload Url: #{username}/#{repository}/#{release}/#{provider}"
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

File.open(filename) do |file|
  req = Net::HTTP::Put.new(upload.path)
  req.content_length = file.size
  req.body_stream = file
  Net::HTTP::Upload.new(req) do |upload|
    printf("Upload: %9s / %9s\n", upload.size.to_i.to_filesize, file.size.to_filesize)
  end
  res = https.request(req)

  case res
  when Net::HTTPSuccess
    puts "Success Upload: #{username}/#{repository}/#{release}/#{provider}"
  end
end

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
  # Create Provider
  res = https.put("/api/v1/box/#{username}/#{repository}/version/#{release}/release", nil, header)

  # Logger
  case res
  when Net::HTTPSuccess
    puts "Success Release: #{username}/#{repository}/#{release}/#{provider}"
  end

  # Close Connection
  https.finish
end
