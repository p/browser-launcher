require 'pathname'
autoload :JSON, 'json'
autoload :FileUtils, 'fileutils'
autoload :YAML, 'yaml'
autoload :Find, 'find'
autoload :Zip, 'zip'
require 'browser_launcher/utils'

module BrowserLauncher
  module Fox
    class ProfileManager
      def initialize(**opts)
        @options = opts.dup.freeze
      end

      attr_reader :options

      def run
        if out_path = options[:save_session]
          save_session(out_path)
        elsif out_path = options[:export_session]
          export_session(out_path)
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
          start = profile_path
          Find.find(start) do |path|
            rel_path = path[start.length+1..]
            next unless rel_path
            next if File.directory?(path)
            archive_path = path[profile_pathname.to_s.length+1..]
            top_comp = rel_path.sub(%r,/.*,, '')
            if [
              'formhistory.sqlite',
              'search.json.mozlz4',
              'sessionstore-backups/recovery.jsonlz4',
              'sessionstore-backups/recovery.baklz4',
              'cookies.sqlite',
              #'storage', # local storage?
              #'storage.sqlite',
            ].include?(top_comp)
            then
              zip.get_output_stream(archive_path) do |f|
                f << File.read(path)
              end
            end
          end
          if cookies_pathname.exist?
            zip.get_output_stream('cookies.sql') do |f|
              BrowserLauncher::Utils.run_stdout(['sqlite3', cookies_path, '.dump']) do |chunk|
                f << chunk
              end
            end
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
        %w(
          cookies.sqlite
          formhistory.sqlite
        ).each do |rel_path|
          this_pathname = profile_pathname.join(rel_path)
          if this_pathname.exist?
            this_out_path = out_path.join(rel_path.sub(/sqlite$/, 'sql'))
            File.open(this_out_path, 'w') do |out_f|
              BrowserLauncher::Utils.run(
                ['sqlite3', this_pathname.to_s, '.dump'],
                stdout: out_f)
            end
          end
        end
      end

      def profile_pathname
        @profile_pathname ||= Pathname.new(options.fetch(:profile_path))
      end

      def profile_path
        profile_pathname.to_s
      end

      def cookies_pathname
        profile_pathname.join('cookies.sqlite')
      end

      def cookies_path
        cookies_pathname.to_s
      end
    end
  end
end
