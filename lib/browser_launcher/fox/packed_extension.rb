# frozen_string_literal: true

require 'zip'
require 'active_support'
require 'active_support/core_ext/hash/conversions'

module BrowserLauncher
  module Fox
    class PackedExtension
      def initialize(path)
        @path = path
      end

      attr_reader :path

      def ext_id
        desc.fetch('id')
      end

      %w(bootstrap unpack version name description creator).each do |key|
        define_method(key) do
          desc.fetch(key)
        end
      end

      def target_application
        desc.fetch('targetApplication')
      end

      def metadata
        @metadata ||= begin
          install_xml = nil
          Zip::File.open(path) do |zip|
            zip.each do |entry|
              if entry.name == 'install.rdf'
                install_xml = entry.get_input_stream.read
              end
            end
          end

          if install_xml.nil?
            raise "No install.rdf in #{path} - not a fox extension?"
          end

          Hash.from_xml(install_xml)
        end
      end

      private

      def desc
        @desc ||= metadata.fetch('RDF').fetch('Description')
      end
    end
  end
end
