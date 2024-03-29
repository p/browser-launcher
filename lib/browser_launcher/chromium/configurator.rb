autoload :Zip, 'zip'
require 'pathname'
require 'fileutils'
require 'json'

module BrowserLauncher
  module Chromium
    class Configurator
      def initialize(home_path, **opts)
        @home_path = home_path
        @options = opts
      end

      attr_reader :home_path
      attr_reader :options

      def profile_pathname
        Pathname.new(File.join(home_path, '.config', 'chromium'))
      end

      def configure
        if options[:overlay_path]
          do_overlay
        end

        path = profile_pathname.join('Local State')

        if File.exist?(path)
          content = JSON.parse(File.read(path))
        else
          FileUtils.mkdir_p(File.dirname(path))
          content = {}
        end

        unless content.key?('browser')
          content['browser'] = {}
        end
        experiments = content['browser']['enabled_labs_experiments'] || []
        # in-product-help-demo-mode-choice@19: the "19" option is "disabled",
        # if these geniuses add more modes the number will likely go up?
        %w(
          allow-insecure-localhost
          allow-popups-during-page-unload@2
          allow-previews@2
          animated-avatar-button@2
          enable-heavy-ad-intervention@1
          enable-lazy-image-loading@3
          enable-native-notifications@2
          enable-paint-holding@1
          enable-resampling-input-events@7
          enable-resampling-scroll-events@7
          enable-show-autofill-signatures
          enable-text-fragment-anchor@1
          extensions-toolbar-menu@1
          fingerprinting-canvas-image-data-noise
          fingerprinting-canvas-measuretext-noise
          fingerprinting-client-rects-noise
          fractional-scroll-offsets@2
          heavy-ad-privacy-mitigations-opt-out@1
          native-file-system-api@2
          ntp-realbox@2
          omnibox-autocomplete-titles@2
          omnibox-drive-suggestions@6
          omnibox-loose-max-limit-on-dedicated-rows@1
          omnibox-max-url-matches@6
          omnibox-pedal-suggestions@2
          omnibox-preserve-default-match-against-async-update@1
          omnibox-rich-entity-suggestions@2
          omnibox-tab-switch-suggestions@2
          omnibox-ui-max-autocomplete-matches@10
          omnibox-zero-suggestions-on-ntp-realbox@2
          omnibox-zero-suggestions-on-ntp@2
          omnibox-zero-suggestions-on-serp@2
          password-leak-detection@2
          prefetch-privacy-changes@1
          smooth-scrolling@2
          tab-hover-cards@4
          username-first-flow@1
          in-product-help-demo-mode-choice@19
        ).each do |exp|
          unless experiments.include?(exp)
            experiments << exp
          end
        end
        content['browser']['enabled_labs_experiments'] = experiments
        # Show title bar:
        # https://stackoverflow.com/questions/11505767/how-can-i-set-chrome-to-use-system-titlebars-and-border-in-preferences-file
        content['browser']['custom_chrome_frame'] = false

=begin
        unless content['profile']
          content['profile'] = {
            'info_cache' => {
              'Default' => {
                'name' => 'Person',
              }
            }
          }
          content['last_active_profiles'] = %w(Default)
        end
=end

        File.open(path, 'w') do |f|
          f << JSON.dump(content)
        end

        path = profile_pathname.join('Default/Preferences')

        if File.exist?(path)
          content = JSON.parse(File.read(path))
        else
          FileUtils.mkdir_p(File.dirname(path))
          content = {}
        end

        if options[:new]
          #content.delete('sessions')
          content.delete('profile')
          #content.delete('protection')
        end

        content['bookmark_bar'] ||= {}
        content['bookmark_bar']['show_on_all_tabs'] = false
        content['extensions'] ||= {}
        content['extensions']['ui'] ||= {}
        content['extensions']['ui']['developer_mode'] = true
        # https://unix.stackexchange.com/questions/110613/how-can-i-make-chrome-stop-asking-to-be-the-default-browser
        content['browser'] ||= {}
        content['browser']['check_default_browser'] = false
        content['browser']['default_browser_infobar_last_declined'] = '13236762067983049'
        # This file has window placement

        content['profile'] ||= {}
        # https://www.howtogeek.com/725208/how-to-turn-off-pop-up-notifications-in-google-chrome/
        content['profile']['default_content_setting_values'] ||= {}
        content['profile']['default_content_setting_values'].update(
          'notifications' => 2,
          'ar' => 2,
          'background_sync' => 2,
          'file_system_write_guard' => 2,
          'geolocation' => 2,
          # HID, different from USB somehow?
          'hid_guard' => 2,
          'idle_detection' => 2,
          'media_stream_camera' => 2,
          'media_stream_mic' => 2,
          'midi_sysex' => 2,
          'payment_handler' => 2,
          'sensors' => 2,
          # serial port access...
          'serial_guard' => 2,
          # usb device access...
          'usb_guard' => 2,
          'vr' => 2,
          'window_placement' => 2,
        )

        content['session'] ||= {}
        # Startup behavior:
        # 1: continue where you left off
        # 4: open new tab page
        # 5: open specific pages
        if options[:restore]
          # https://superuser.com/questions/1697483/how-can-i-setup-chrome-from-the-preferences-file-to-restore-the-tabs-from-last-s
          content['session']['restore_on_startup'] = 1
          # Without this chromium still shows the crashed UI even though
          # it's told to just restore the session.
          # https://superuser.com/questions/237608/how-to-hide-chrome-warning-after-crash
          content['profile']['exit_type'] = 'Normal'
        elsif options[:new]
          content['session']['restore_on_startup'] = 0
        else
          content['session'].delete('restore_on_startup')
        end

        # Alternatively for ungoogled-chromium:
        # hide-crashed-bubble

        File.open(path, 'w') do |f|
          f << JSON.dump(content)
        end

        path = profile_pathname.join('First Run')
        FileUtils.touch(path)

        if options[:ca_certs]
          create_nss_db
        end
      end

      private

      def create_nss_db
        # https://serverfault.com/questions/414578/certutil-function-failed-security-library-bad-database
        # https://stackoverflow.com/questions/19692787/how-to-install-certificate-in-browser-settings-using-command-prompt
        # certutil is in libnss3-tools

        db_dir = File.expand_path('~/.pki/nssdb')
        FileUtils.mkdir_p(db_dir)

        unless File.exist?(File.join(db_dir, 'pkcs11.txt'))
          system("certutil -d sql:#{db_dir} -N --empty-password")
        end

        options.fetch(:ca_certs).each do |ca_path|
          puts "Adding #{ca_path}"
          system("certutil -d sql:#{db_dir} -A -n '#{File.basename(ca_path)}' -t 'TCu,Cu,Tu' -i '#{ca_path}'")
        end
      end

      def do_overlay
        path = options.fetch(:overlay_path)
        if File.directory?(path)
          FileUtils.copy_entry(path, home_path)
        else
          Zip::File.foreach(path) do |entry|
            next if entry.directory?
            entry.get_input_stream do |io|
              src_path = if entry.name =~ %r,\Aconfig(\z|/),
                '.' + entry.name
              else
                entry.name
              end
              write_path = File.join(home_path, src_path)
              p write_path
              FileUtils.mkdir_p(File.dirname(write_path))
              File.open(write_path, 'w') do |f|
                while chunk = io.read(10000)
                  f << chunk
                end
              end
            end
          end
        end
      end
    end
  end
end
