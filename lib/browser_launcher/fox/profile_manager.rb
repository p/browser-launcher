require 'pathname'
autoload :JSON, 'json'
autoload :FileUtils, 'fileutils'
autoload :YAML, 'yaml'
autoload :Find, 'find'
autoload :Zip, 'zip'
require 'browser_launcher/utils'
require 'browser_launcher/fox/fs_locations'
autoload :LZ4, 'extlz4'

module BrowserLauncher
  module Fox
    class ProfileManager
      include FsLocations

      def initialize(**opts)
        @options = opts.dup.freeze
      end

      attr_reader :options

      def binary_path
        options[:binary_path] || 'firefox'
      end

      def run
        if options[:list_profiles]
          all_profiles_names.each do |name|
            puts name
          end
        elsif out_path = options[:save_session]
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
        unless profile_pathname.exist?
          raise "Profile path does not exist: #{profile_path}"
        end

        out_path = Pathname.new(out_path)
        %w(
          search.json.mozlz4
          sessionstore-backups/recovery.jsonlz4
          sessionstore-backups/recovery.baklz4
        ).each do |rel_path|
          this_pathname = profile_pathname.join(rel_path)
          if this_pathname.exist?
            this_out_path = out_path.join(rel_path.sub(/lz4$/, '').sub(/\.json\.moz$/, '.json'))
            FileUtils.mkdir_p(File.dirname(this_out_path))
            File.open(this_out_path, 'w') do |out_f|
              File.open(this_pathname) do |f|
                # TODO Verify size
                f.read(12)
                out_f.write(LZ4.block_decode(f.read))
              end
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
        @profile_pathname ||= Pathname.new(profile_path)
      end

      def profile_path
        options[:profile_path] or begin
          path_for_profile_name(options.fetch(:profile))
        end
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
