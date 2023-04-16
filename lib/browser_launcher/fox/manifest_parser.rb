module BrowserLauncher
  module Fox
    module ManifestParser

      private

      def load_install_rdf(contents)
        metadata = Hash.from_xml(contents)
        desc = metadata.fetch('RDF').fetch('Description')
        %w(bootstrap unpack version name description creator).each do |key|
          instance_variable_set("@#{key}", desc.fetch(key))
        end
        @ext_id = desc.fetch('id')
        @target_application = desc.fetch('targetApplication')
      end

      def load_manifest_json(contents)
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
