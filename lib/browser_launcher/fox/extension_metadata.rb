# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'json'

module BrowserLauncher
  module Fox
    class ExtensionsMetadata
      def initialize(path)
        @path = path

        load!
      end

      attr_reader :path

      def load!
        data = if File.exist?(path)
          JSON.load(File.read(path))
        else
          {
            schemaVersion: 24,
            addons: addons,
          }
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
