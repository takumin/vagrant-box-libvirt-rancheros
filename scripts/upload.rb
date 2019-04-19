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
      'username'          => username,
      'name'              => repository,
      'short_description' => repository,
      'description'       => repository,
      'is_private'        => false,
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
      'version'     => version,
      'description' => "#{repository} #{version}",
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
    puts "Success Upload"
  end
end
