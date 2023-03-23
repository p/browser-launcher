# frozen_string_literal: true

require 'json'
require 'browser_launcher/indifferent_hash'

module BrowserLauncher
  module Fox
    class ExtensionsMetadata
      def initialize(path)
        @path = path

        load!
      end

      attr_reader :path

      def default
        {
          schemaVersion: 24,
          addons: [],
        }
      end

      def load!
        data = if File.exist?(path)
          File.open(path) do |f|
            begin
              JSON.load(f)
            rescue JSON::ParserError => exc
              msg = exc.to_s
              if msg.length > 300
                msg = msg[0..150] + '...' + msg[-150...-1]
              end
              puts "Error parsing extensions metadata: #{exc.class}: #{msg}"
              default
            end
          end
        else
          default
        end
        @data = ActiveSupport::HashWithIndifferentAccess.new(data)
      end

      attr_reader :data

      def addon(name)
        data.fetch(:addons).detect do |addon|
          # Not all addons have names
          addon[:name] == name
        end
      end

      def set_addon(name, info)
        found = false
        data.fetch(:addons).each do |addon|
          if addon[:name] == name
            found = true
            addon.update(info)
            break
          end
        end
        unless found
          data[:addons] << ActiveSupport::HashWithIndifferentAccess.new(info).update('name' => name)
        end
      end

      def dump!
        File.open(path, 'w') do |f|
          f << data
        end
      end
    end
  end
end
