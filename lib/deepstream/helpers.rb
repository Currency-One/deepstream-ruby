require 'json'

module Deepstream
  module Helpers
    SCHEME = 'ws://'
    DEFAULT_PORT = 6020
    DEFAULT_PATH = 'deepstream'

    def self.to_deepstream_type(value)
      case value
      when Hash then "O#{value.to_json}"
      when String then "S#{value}"
      when Numeric then "N#{value}"
      when TrueClass then 'T'
      when FalseClass then 'F'
      when NilClass then 'L'
      end
    end

    def self.to_type(payload)
      case payload[0]
      when 'O' then JSON.parse(payload[1..-1])
      when '{' then JSON.parse(payload)
      when 'S' then payload[1..-1]
      when 'N' then payload[1..-1].to_f
      when 'T' then true
      when 'F' then false
      when 'L' then nil
      else JSON.parse(payload)
      end
    end

    def self.default_options
      {
        ack_timeout: nil,
        autologin: true,
        credentials: {},
        heartbeat_interval: nil,
        max_reconnect_attempts: 5,
        max_reconnect_interval: 30,
        reconnect_interval: 1,
        verbose: false
      }
    end

    def self.get_url(url)
      url.tap do |url|
        url.prepend(SCHEME) unless url.start_with?(SCHEME)
        url.concat(":#{DEFAULT_PORT}") unless url[/\:\d+/]
        url.concat("/#{DEFAULT_PATH}") unless url[/\/\w+$/]
      end
    end
  end
end
