# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require 'json'
require 'inifile'
require 'browser_launcher/utils'
require 'browser_launcher/launcher_base'

module BrowserLauncher
  module Fox
    class Launcher < LauncherBase

      private

      DATA_PATH = File.join(File.dirname(__FILE__), '../../../data/fox')

      def process_args
        OptionParser.new do |opts|
          opts.banner = "Usage: launch-fox [options]"

          opts.on("-b", "--binary=PATH", "Launch the binary at PATH (default: firefox)") do |v|
            if v.include?('/')
              Utils.verify_path_exists(v, 'binary')
            else
              # TODO locate the binary in PATH, warn/error if missing
            end
            options[:binary_path] = v
          end

          opts.on("-c", "--ca=PATH", "Add a CA certificate to trust store (can be given more than once)") do |value|
            options[:ca_certs] ||= []
            options[:ca_certs] << Utils.verify_path_exists(value, 'CA certificate')
          end

          opts.on("-S", "--default-search=NAME", "Specify default search engine name") do |v|
            options[:default_search_name] = v
          end

          opts.on("-e", "--ext=PATH", "Load unpacked extension at PATH (can be given more than once)") do |v|
            options[:extensions] ||= []
            options[:extensions] << Utils.verify_path_exists(v, 'unpacked extension')
          end

          opts.on("-f", "--force", "Launch even when requested resources (extensions, CA certs, configuration files) are not present") do
            options[:force] = true
          end

          opts.on('-g', '--group-access', 'Make profile directory group-accessible (read & write)') do
            options[:group_accessible] = true
          end

          opts.on('-G', '--gui', 'Report errors using yad (for invocation from e.g. window manager menu)') do
            options[:gui] = true
          end

          opts.on("-p", "--profile=NAME", "Use specified profile name") do |v|
            options[:profile_name] = v
          end

          opts.on("-u", "--user=USER", "Launch as given user") do |v|
            options[:user] = v
          end

          opts.on("--user-js=PATH", "Path to user.js") do |v|
            options[:user_js_path] = Utils.verify_path_exists(v, 'user.js')
          end

          opts.on("--user-chrome-css=PATH", "Path to userChrome.css") do |v|
            options[:user_chrome_css_path] = Utils.verify_path_exists(v, 'userChrome.css')
          end

          opts.on("--user-content-css=PATH", "Path to userContent.css") do |v|
            options[:user_content_css_path] = Utils.verify_path_exists(v, 'userContent.css')
          end

          opts.on("--policies=PATH", "Path to policies.json") do |v|
            options[:policies_path] = Utils.verify_path_exists(v, 'policies.json')
          end

          opts.on('--install-global-ext=PATH', '-I', 'Install global extension at PATH into browser directory specified by -b') do |v|
            options[:install_global_ext] = v
          end
        end.parse!

        if ARGV.any?
          raise "launch-fox does not accept positional arguments"
        end

        if path = options[:install_global_ext]
          require 'browser_launcher/fox/extension'

          dest_path = options[:binary_path]
          if dest_path.nil?
            raise "Use -b to specify path to browser installation or fox binary"
          end
          unless File.directory?(dest_path)
            dest_path = File.dirname(dest_path)
          end

          # Sanity check
          unless File.exist?(File.join(dest_path, 'libxul.so'))
            raise "#{dest_path} does not look like a browser installation root"
          end

          dest_path = File.join(dest_path, 'distribution/extensions')
          FileUtils.mkdir_p(dest_path)

          meta = Extension.new(path)
          dest = File.join(dest_path, meta.ext_id)

          if File.directory?(path)
            FileUtils.rm_rf(dest)
            FileUtils.cp_r(path, dest)
          else
            dest = "#{dest}.xpi"
            FileUtils.rm_f(dest)
            FileUtils.cp(path, dest)
          end

          exit
        end
      end

      def data_path
        File.join(File.dirname(__FILE__), '../../../data/fox')
      end

      def profile
        options[:profile_name] || 'default'
      end

      def binary_path
        options[:binary_path] || 'firefox'
      end

      def build_cmd
        cmd = []
        if certs = options[:ca_certs]
          certs.each do |ca_path|
            ARGV << '-c' << ca_path
          end
        end
        if options[:gui]
          cmd << '-G'
        end
        options[:extensions]&.each do |ext|
          cmd += ['-e', ext]
        end
        if ds = options[:default_search_name]
          cmd += ['-S', ds]
        end
        if path = options[:user_js_path]
          cmd += ['--user-js', path]
        end
        if path = options[:user_chrome_css_path]
          cmd += ['--user-chrome-css', path]
        end
        if path = options[:user_content_css_path]
          cmd += ['--user-content-css', path]
        end
        if name = options[:profile_name]
          cmd += ['-p', name]
        end
        if path = options[:binary_path]
          cmd += ['-b', path]
        end
        if path = options[:policies_path]
          cmd += ['--policies', path]
        end
        if options[:group_accessible]
          cmd << '-g'
        end
        if options[:force]
          cmd << '-f'
        end
        cmd += ARGV
      end

      def rel_profiles_dir
        @profiles_dir ||= case File.basename(binary_path)
        when 'waterfox'
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

      def profile_basename
        "gen.#{profile}"
      end

      def profile_path
        @profile_path ||= File.join(profiles_dir, profile_basename)
      end

      def launch
        maybe_relaunch_as_target_user

        catalog_path = File.join(profiles_dir, 'profiles.ini')

        if File.exist?(catalog_path)
          ini = IniFile.new(filename: catalog_path, separator: '')
        else
          ini = IniFile.new(separator: '')
        end

        ini['Profile0'] = {
          Name: profile,
          IsRelative: 1,
          Path: profile_basename,
        }

        FileUtils.mkdir_p(profiles_dir)
        ini.write(filename: catalog_path)

        FileUtils.mkdir_p(profile_path)

        chrome_path = File.join(profile_path, 'chrome')
        FileUtils.mkdir_p(chrome_path)
        if path = options[:user_js_path]
          FileUtils.cp(path, File.join(chrome_path, 'user.js'))
        end
        if path = options[:user_chrome_css_path]
          FileUtils.cp(path, File.join(chrome_path, 'userChrome.css'))
        end
        if path = options[:user_content_css_path]
          FileUtils.cp(path, File.join(chrome_path, 'userContent.css'))
        end
        if path = options[:policies_path]
          FileUtils.mkdir_p(File.join(profile_path, 'system/distribution'))
          FileUtils.cp(path, File.join(profile_path, 'system/distribution/policies.json'))
        end

        if search_engine_name = options[:default_search_name]
          search_path = File.join(DATA_PATH, 'search.json.in')
          search = File.open(search_path) do |f|
            JSON.load(f)
          end

          known_names = search.fetch('engines').map { |e| e.fetch('_name') }
          unless known_names.include?(search_engine_name)
            sn = known_names.detect do |n|
              n.downcase == search_engine_name
            end
            if sn
              puts "Correcting search engine name: #{search_engine_name} -> #{sn}"
              search_engine_name = sn
            else
              raise "Unknown search engine: #{search_engine_name}"
            end
          end

          hash = HashGenerator.generate(:waterfox, profile_basename, search_engine_name)
          search['metaData'] = {
            current: search_engine_name,
            hash: hash,
          }
          search = JSON.dump(search)
          # https://github.com/dearblue/ruby-extlz4
          # https://gist.github.com/Tblue/62ff47bef7f894e92ed5
          # https://gist.github.com/kaefer3000/73febe1eec898cd50ce4de1af79a332a
          # use lz4jsoncat in lz4json debian package to verify
          require 'extlz4'
          File.open(File.join(profile_path, 'search.json.mozlz4'), 'wb') do |f|
            f << "mozLz40\0"
            f << [search.length].pack('l<')
            f << LZ4.block_encode(search)
          end
        end

        if certs = options[:ca_certs]
          db_dir = profile_path
          FileUtils.mkdir_p(db_dir)

          unless File.exist?(File.join(db_dir, 'pkcs11.txt'))
            #system("certutil -d dbm:#{db_dir} -N --empty-password")
          end

          certs.each do |ca_path|
            puts "Adding #{ca_path}"
            system("certutil -d dbm:#{db_dir} -A -n '#{File.basename(ca_path)}' -t 'TCu,Cu,Tu' -i '#{ca_path}'")
          end
        end

        if exts = options[:extensions]
          addons = []
          metadata_path = File.join(profile_path, 'extensions.json')
          md = ExtensionsMetadata.new(metadata_path)

          exts.each do |ext_path|
            ext = PackedExtension.new(ext_path)

            ext_dir = File.join(profile_path, 'extensions')
            FileUtils.mkdir_p(ext_dir)
            FileUtils.cp(ext_path, File.join(ext_dir, "#{ext.ext_id}.xpi"))

            info = md.addon(ext.name) || {}
            info.update(
              id: ext.ext_id,
              location: 'app-profile',
              version: ext.version,
              type: 'extension',
              bootstrap: ext.bootstrap,
              defaultLocale: {
                name: ext.name,
                description: ext.description,
                creator: ext.creator,
                homepageURL: nil,
              },
              visible: true,
              active: true,
              userDisabled: false,
              appDisabled: false,
              targetApplications: [ext.target_application],
              path: File.realpath(ext_path),
            )
            md.set_addon(ext.name, info)
          end

          md.dump!
        end

        src_path = File.join(profile_path, 'chrome/user.js')
        if File.exist?(src_path)
          contents = File.read(src_path)
          File.open(File.join(profile_path, 'prefs.js'), 'a') do |f|
            f << "\n"
            f << contents
          end
        end

        # Waterfox and waterfox classic put profiles in the same place, ugh.
        #exec(binary, '-P', profile)
        cmd = [binary_path, '--no-remote', '--profile', profile_path]
        run_browser(cmd)
      end
    end
  end
end
