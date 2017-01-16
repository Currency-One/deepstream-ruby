require 'json'

module Deepstream
  module Helpers
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
        autologin: true,
        credentials: {},
        heartbeat_interval: nil,
        verbose: false
      }
    end
  end
end
