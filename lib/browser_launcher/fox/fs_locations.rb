# frozen_string_literal: true

module BrowserLauncher
  module Fox
    module FsLocations

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
    end
  end
end
