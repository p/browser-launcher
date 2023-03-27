# frozen_string_literal: true

require 'zip'
require 'active_support'
require 'active_support/core_ext/hash/conversions'

module BrowserLauncher
  module Fox
    class PackedExtension
      def initialize(path)
        @path = path

        load!
      end

      attr_reader :path

      attr_reader :ext_id, :bootstrap, :unpack, :version,
        :name, :description, :creator, :target_application

      def load!
        install_xml = nil
        manifest_json = nil

        Zip::File.open(path) do |zip|
          zip.each do |entry|
            if entry.name == 'install.rdf'
              install_xml = entry.get_input_stream.read
            end
            if entry.name == 'manifest.json'
              manifest_json = entry.get_input_stream.read
            end
          end
        end

        if install_xml.nil? && manifest_json.nil?
          raise "No install.rdf or manifest.json in #{path} - not a fox extension?"
        end

        if install_xml && manifest_json
          raise "Both install.rdf and manifest.json are present in #{path} - don't know which to choose"
        end

        if install_xml
          load_rdf(install_xml)
        else
          load_chrome(manifest_json)
        end
      end

      def load_rdf(contents)
        metadata = Hash.from_xml(contents)
        desc = metadata.fetch('RDF').fetch('Description')
        %w(bootstrap unpack version name description creator).each do |key|
          instance_variable_set("@#{key}", desc.fetch(key))
        end
        @ext_id = desc.fetch('id')
        @target_application = desc.fetch('targetApplication')
      end

      def load_chrome(contents)
        metadata = JSON.parse(contents)
        @ext_id = metadata.fetch('applications').fetch('gecko').fetch('id')
        @version = metadata.fetch('version')
        @name = metadata.fetch('name')
        @description = metadata.fetch('description')
        @creator = metadata.fetch('author')
      end
    end
  end
end
