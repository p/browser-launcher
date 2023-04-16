# frozen_string_literal: true

require 'zip'
require 'active_support'
require 'active_support/core_ext/hash/conversions'
require 'browser_launcher/fox/manifest_parser'

module BrowserLauncher
  module Fox
    class PackedExtension
      include ManifestParser

      def initialize(path)
        @path = path

        load!
      end

      attr_reader :path

      attr_reader :ext_id, :bootstrap, :unpack, :version,
        :name, :description, :creator, :target_application

      def load!
        install_rdf = nil
        manifest_json = nil

        Zip::File.open(path) do |zip|
          zip.each do |entry|
            if entry.name == 'install.rdf'
              install_rdf = entry.get_input_stream.read
            end
            if entry.name == 'manifest.json'
              manifest_json = entry.get_input_stream.read
            end
          end
        end

        if install_rdf.nil? && manifest_json.nil?
          raise "No install.rdf or manifest.json in #{path} - not a fox extension?"
        end

        if install_rdf && manifest_json
          raise "Both install.rdf and manifest.json are present in #{path} - don't know which to choose"
        end

        if install_rdf
          load_install_rdf(install_rdf)
        else
          load_manifest_json(manifest_json)
        end
      end
    end
  end
end
