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
          save_session(out_path)
        elsif in_path = options[:restore_session]
          restore_session(in_path)
        elsif out_path = options[:export_session]
          export_session(out_path)
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
          BrowserLauncher::Utils.run(['sqlite3', cookies_path, '.dump'])
        end
      end

      private

      def save_session(out_path)
        if File.exist?(out_path)
          FileUtils.rm(out_path)
        end
        # create option appends to existing file, thus rm earlier.
        Zip::File.open(out_path, create: true) do |zip|
          start = default_pathname.to_s
          Find.find(start) do |path|
            rel_path = path[start.length+1..]
            next unless rel_path
            next if File.directory?(path)
            archive_path = path[profile_pathname.to_s.length+1..]
            top_comp = rel_path.sub(%r,/.*,, '')
            if [
              'Cookies',
              'Cookies-journal',
              'Session Storage',
              'Sessions',
              'Preferences',
              #'Secure Preferences',
            ].include?(top_comp)
            then
              zip.get_output_stream(archive_path) do |f|
                f << File.read(path)
              end
            end
          end
          if cookies_pathname.exist?
            zip.get_output_stream('config/chromium/Default/Cookies.sql') do |f|
              BrowserLauncher::Utils.run_stdout(['sqlite3', cookies_path, '.dump']) do |chunk|
                f << chunk
              end
            end
          end
        end
      end

      def restore_session(in_path)
        Zip::File.open(in_path) do |zip|
          zip.each do |zip_entry|
            dn = File.dirname(zip_entry.name)
            dest_dn = profile_pathname.join('.' + dn)
            FileUtils.mkdir_p(dest_dn)
            dest_path = File.join(dest_dn, File.basename(zip_entry.name))
            zip_entry.extract(dest_path)
          end
        end
      end

      def export_session(out_path)
        out_path = Pathname.new(out_path)
        [
          'Default/Preferences',
          'Default/Secure Preferences',
          'Local State',
        ].each do |partial_name|
          dest = out_path.join(".config/chromium/#{partial_name}.yml")
          FileUtils.mkdir_p(dest.dirname)
          p dest
          File.open(dest, 'w') do |out_f|
            File.open(config_pathname.join(partial_name)) do |f|
              out_f << YAML.dump(JSON.load(f))
            end
          end
        end
        File.open(out_path.join(".config/chromium/Default/Cookies.sql"), 'w') do |out_f|
          BrowserLauncher::Utils.run(
            ['sqlite3', cookies_path, '.dump'],
            stdout: out_f)
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

      def cookies_pathname
        default_pathname.join('Cookies')
      end

      def cookies_path
        cookies_pathname.to_s
      end
    end
  end
end
