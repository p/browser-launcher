# frozen_string_literal: true

require 'optparse'
require 'browser_launcher/utils'
require 'browser_launcher/launcher_base'

module BrowserLauncher
  module Chromium
    class Launcher < LauncherBase

      private

      def process_args
        OptionParser.new do |opts|
          opts.banner = "Usage: launch-chromium [options]"

          opts.on("-b", "--binary=PATH", "Launch the binary at PATH (default: chrome)") do |v|
            if v.include?('/')
              Utils.verify_path_exists(v, 'binary')
            else
              # TODO locate the binary in PATH, warn/error if missing
            end
            options[:binary_path] = v
          end

          opts.on("-c", "--ca=PATH", "Add a CA certificate to trust store (can be given more than once)") do |v|
            options[:ca_certs] ||= []
            options[:ca_certs] << v
          end

          opts.on("-S", "--default-search=NAME", "Specify default search engine name") do |v|
            options[:default_search_name] = v
          end

          opts.on("-e", "--ext=PATH", "Load unpacked extension at PATH (can be given more than once)") do |v|
            options[:extensions] ||= []
            options[:extensions] << v
          end

          opts.on("-E", "--exist-ext PATH", "Load unpacked extension at PATH if it exists") do |v|
            if File.directory?(v)
              options[:extensions] ||= []
              options[:extensions] << v
            end
          end

          opts.on("-f", "--force", "Launch even when extensions and CA certs requested are not present") do
            options[:force] = true
          end

          opts.on('-g', '--group-access', 'Make profile directory group-accessible (read & write)') do
            options[:group_accessible] = true
          end

          opts.on('-G', '--gui', 'Report errors using yad (for invocation from e.g. window manager menu)') do
            options[:gui] = true
          end

          opts.on("-n", "--new", "Assume a fresh launch") do
            options[:new] = true
          end

          opts.on("--min-process", "Minimize number of processes chromium will try to create") do
            options[:min_process] = true
          end

          opts.on('-o', '--overlay=PATH', 'Copy specified directory or extract specified zip file over base directory') do |v|
            options[:overlay_path] = v
          end

          opts.on("-p", "--profile=NAME", "Use specified profile name") do |v|
            options[:profile_name] = v
          end

          opts.on('-r', '--restore', 'Restore session if possible') do
            options[:restore] = true
          end

          opts.on('-R', '--no-restore', 'Do not restore session and disable associated UI') do
            options[:restore] = false
          end

          opts.on("-u", "--user=USER", "Launch as given user") do |v|
            options[:user] = v
          end
        end.parse!

        if ARGV.any?
          raise "launch-chromium does not accept positional arguments"
        end

        options[:extensions] = Utils.check_or_filter_paths(
          options[:extensions], "Unpacked extension",
          force: options[:force], gui: options[:gui])
        options[:ca_certificates] = Utils.check_or_filter_paths(
          options[:ca_certificates], "CA certificate",
          force: options[:force], gui: options[:gui])
      end

      def profile
        options[:profile_name] || 'default'
      end

      def binary_path
        options[:binary_path] || begin
          chromium_bin = nil
          %w(chromium chrome).each do |bn|
            ENV.fetch('PATH').split(':').each do |dn|
              if File.exist?(path = File.join(dn, bn))
                chromium_bin = path
                break
              end
            end
            break if chromium_bin
          end

          if chromium_bin.nil?
            raise "chromium or chrome not found in PATH"
          end

          # Resolve local symlinks so that the binary can be spawned via sudo.
          chromium_bin = File.realpath(chromium_bin)
        end
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
        if name = options[:profile_name]
          cmd += ['-p', name]
        end
        cmd += ['-b', binary_path]
        if options[:group_accessible]
          cmd << '-g'
        end
        if options[:force]
          cmd << '-f'
        end
        if overlay_path = options[:overlay_path]
          cmd += ['-o', overlay_path]
        end
        if options[:new]
          cmd << '-n'
        end
        if options[:min_process]
          cmd << '--min-process'
        end
        case options[:restore]
        when nil
        when false
          cmd << '-R'
        else
          cmd << '-r'
        end
        cmd += ARGV
      end

      def launch
        maybe_relaunch_as_target_user

        if profile == target_user
          profile_base = "/home/#{target_user}"
          profile_args = []
        else
          profile_base = "/home/#{target_user}/#{profile}"
          profile_args = ["HOME=#{profile_base}", "XDG_HOME=#{profile_base}"]
        end

        # Chromium disrespects umask for downloads directory, try to fix.
        dl_target = if target_user == "br-#{profile}"
          #"/home/br-downloads/#{target_user}"
          "/home/br-downloads/#{target_user}/#{profile}"
        else
          "/home/br-downloads/#{target_user}/#{profile}"
        end
        FileUtils.mkdir_p(dl_target)
        dl_local = File.join(profile_base, 'Downloads')
        if File.exist?(dl_local)
          if !File.symlink?(dl_local)
            Utils.warning("Downloads directory not a symlink",
              "Downloads directory is not a symlink:\n#{dl_local}",
              gui: options[:gui])
            FileUtils.chmod(0770, dl_local)
          end
        else
          FileUtils.mkdir_p(File.dirname(dl_local))
          FileUtils.ln_s(dl_target, dl_local)
        end

        extension_arg = if options[:extensions]
          "--load-extension=#{options[:extensions].join(',')}"
        else
          ''
        end

        Configurator.new(profile_base, **options).configure

        cmd = ['env',
          *profile_args,
          "XAUTHORITY=#{target_xauthority_path}",
          binary_path,
          '--disable-notifications',
          '--disable-smooth-scrolling',
          '--disable-sync',
          '--disable-gaia-services',
          *extension_arg,
        ]
        if options[:new] || options[:restore] == false
          cmd << '--disable-session-crashed-bubble'
        end
        if options[:min_process]
          # https://stackoverflow.com/questions/51320322/how-to-disable-site-isolation-in-google-chrome
          cmd << '--disable-features=IsolateOrigins,site-per-process'
          cmd << '--disable-site-isolation-trials'
          # https://superuser.com/questions/952302/how-to-make-google-chrome-or-chromium-use-less-memory
          cmd << '--renderer-process-limit=2'
        end
        run_browser(cmd)
      end
    end
  end
end
