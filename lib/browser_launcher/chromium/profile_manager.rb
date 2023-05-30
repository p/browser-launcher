require 'pathname'
autoload :JSON, 'json'
autoload :FileUtils, 'fileutils'
autoload :YAML, 'yaml'
autoload :Find, 'find'
autoload :Zip, 'zip'
require 'browser_launcher/utils'

module BrowserLauncher
  module Chromium
    class ProfileManager
      def initialize(**opts)
        @options = opts.dup.freeze
      end

      attr_reader :options

      def run
        if out_path = options[:save_session]
          if File.exist?(out_path)
            FileUtils.rm(out_path)
          end
          # create option appends to existing file, thus rm earlier.
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
            cookies_path = default_pathname.join('Cookies')
            if cookies_path.exist?
              zip.get_output_stream('.config/chromium/Default/Cookies.sql') do |f|
                BrowserLauncher::Utils.run_stdout(['sqlite3', cookies_path.to_s, '.dump']) do |chunk|
                  f << chunk
                end
              end
            end
          end
        elsif options[:dump_preferences]
          File.open(default_pathname.join('Preferences')) do |f|
            puts YAML.dump(JSON.load(f))
          end
        elsif options[:dump_secure_preferences]
          File.open(default_pathname.join('Secure Preferences')) do |f|
            puts YAML.dump(JSON.load(f))
          end
        elsif options[:dump_local_state]
          File.open(config_pathname.join('Local State')) do |f|
            puts YAML.dump(JSON.load(f))
          end
        elsif options[:dump_cookies]
          cookies_path = default_pathname.join('Cookies')
          BrowserLauncher::Utils.run(['sqlite3', cookies_path.to_s, '.dump'])
        end
      end

      def profile_pathname
        @profile_pathname ||= Pathname.new(options.fetch(:profile_path))
      end

      def config_pathname
        profile_pathname.join('.config/chromium')
      end

      def default_pathname
        config_pathname.join('Default')
      end
    end
  end
end

