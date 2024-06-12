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

      def all_profiles_names
        # Here we can either parse profiles.ini and get the known profiles
        # reliably, or take all subdirectories.
        # Unfortunately now mozilla appears to dump random junk into the
        # top-level profiles directory ("Crash Reports", "Pending Pings")
        # therefore simply iterating the directories is insufficient.
        ini_path = File.join(profiles_dir, 'profiles.ini')

        if File.exist?(ini_path)
          # Now we *could* parse the file correctly, but for now take a shortcut
          contents = File.read(ini_path)
          contents.scan(/^Name=(.+)/)
        else
          []
        end
      end
    end
  end
end
