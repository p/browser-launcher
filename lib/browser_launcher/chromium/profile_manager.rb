require 'pathname'
autoload :Find, 'find'
autoload :Zip, 'zip'

module BrowserLauncher
  module Chromium
    class ProfileManager
      def initialize(**opts)
        @options = opts.dup.freeze
      end

      attr_reader :options

      def run
        if out_path = options[:save_session]
          Zip::File.open(out_path, create: true) do |zip|
            start = profile_pathname.join('.config/chromium/Default').to_s
            Find.find(start) do |path|
              rel_path = path[start.length+1..]
              next unless rel_path
              next if File.directory?(rel_path)
              archive_path = path[profile_pathname.to_s.length+1..]
              top_comp = rel_path.sub(%r,/.*,, '')
              if [
                'Cookies',
                'Cookies-journal',
                'Session Storage',
                'Sessions',
              ].include?(top_comp)
              then
                zip.get_output_stream(archive_path) do |f|
                  f << File.read(path)
                end
              end
            end
          end
        end
      end

      def profile_pathname
        @profile_pathname ||= Pathname.new(options.fetch(:profile_path))
      end
    end
  end
end

