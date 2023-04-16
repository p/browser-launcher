# frozen_string_literal: true

require 'browser_launcher/fox/manifest_parser'

module BrowserLauncher
  module Fox
    class UnpackedExtension
      include ManifestParser

      def initialize(path)
        @path = path

        load!
      end

      attr_reader :path

      attr_reader :ext_id, :bootstrap, :unpack, :version,
        :name, :description, :creator, :target_application

      def load!
        install_rdf = File.join(path, 'install.rdf')
        unless File.exist?(install_rdf)
          install_rdf = nil
        end

        manifest_json = File.join(path, 'manifest.json')
        unless File.exist?(manifest_json)
          manifest_json = nil
        end

        if install_rdf.nil? && manifest_json.nil?
          raise "No install.rdf or manifest.json in #{path} - not a fox extension?"
        end

        if install_rdf && manifest_json
          raise "Both install.rdf and manifest.json are present in #{path} - don't know which to choose"
        end

        if install_rdf
          load_install_rdf(File.read(install_rdf))
        else
          load_manifest_json(File.read(manifest_json))
        end
      end
    end
  end
end
