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

          opts.on("-E", "--exist-ext PATH", "Load unpacked extension at PATH if it exists") do |v|
            if File.directory?(v)
              options[:extensions] ||= []
              options[:extensions] << v
            end
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

          opts.on("-p", "--profile=NAME", "Use specified profile name") do |v|
            options[:profile_name] = v
          end

          opts.on("-u", "--user=USER", "Launch as given user") do |v|
            options[:user] = v
          end
        end.parse!

        if ARGV.any?
          raise "launch-chromium does not accept positional arguments"
        end
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
          '--disable-session-crashed-bubble',
          '--disable-gaia-services',
          *extension_arg,
        ]
        run_browser(cmd)
      end
    end
  end
end
