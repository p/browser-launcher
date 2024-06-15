# frozen_string_literal: true

require 'browser_launcher/fox/profile_catalog'

module BrowserLauncher
  module Fox
    module FsLocations

      BROWSER_BINARY_LIST = %w(
        waterfox-classic
        waterfox
        firefox
        palemoon
      ).freeze

      PROFILE_DIR_LIST = %w(
        .waterfox-classic
        .waterfox
        .mozilla/firefox
        .moonchild productions/pale moon
      ).freeze

      def rel_profiles_dir
        @profiles_dir ||= case File.basename(binary_path)
        when 'waterfox', 'waterfox-classic'
          if binary_path =~ /waterfox-classic/
            '.waterfox-classic'
          else
            '.waterfox'
          end
        when 'firefox'
          '.mozilla/firefox'
        when 'palemoon'
          '.moonchild productions/pale moon'
        else
          raise "Unknown browser #{binary_path}"
        end
      end

      def profiles_dir
        @profiles_dir ||= File.join(File.expand_path('~'), rel_profiles_dir)
      end

      def all_profiles_names
        profile_catalog.profile_names
      end

      def profile_catalog
        @profile_catalog ||= ProfileCatalog.new(profiles_dir)
      end

      def path_for_profile_name(profile_name)
        profile_catalog.profile_path(profile_name)
      end
    end
  end
end
