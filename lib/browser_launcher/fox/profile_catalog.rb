# frozen_string_literal: true

require 'inifile'

module BrowserLauncher
  module Fox
    class ProfileCatalog
      def initialize(profiles_dir)      
        @profiles_dir = profiles_dir
      end
      
      attr_reader :profiles_dir
      
      def profile_names
        profile_keys.map do |key|
          catalog[key][:Name]
        end
      end
      
      def add_profile!(profile_name, profile_basename)
        catalog["Profile#{next_profile_id}"] = {
          Name: profile,
          IsRelative: 1,
          Path: profile_basename,
        }
      end
      
      def profile_path(profile_name)
        section = catalog[profile_id(profile_name)]
        if section['IsRelative']
          File.join(profiles_dir, section.fetch('Path'))
        else
          section.fetch('Path')
        end
      end
      
      private
      
      def catalog_path
        @catalog_path ||= File.join(profiles_dir, 'profiles.ini')
      end
      
      def catalog
        @catalog ||= if File.exist?(catalog_path)
          IniFile.new(filename: catalog_path, separator: '')
        else
          IniFile.new(separator: '')
        end
      end
      
      def save!
        FileUtils.mkdir_p(profiles_dir)
        catalog.write(filename: catalog_path)
      end
      
      def profile_keys
        catalog.sections.grep(/^Profile/)
      end
      
      def next_profile_id
        keys = profile_keys
        if keys.empty?
          0
        else
          Integer(keys.sub('Profile', '')) + 1
        end
      end
      
      def profile_id(profile_name)
        catalog.sections.detect do |section|
          catalog[section]['Name'] == profile_name
        end
      end
    end
  end
end
