# frozen_string_literal: true

require 'etc'
require 'browser_launcher/utils'

module BrowserLauncher
  class LauncherBase
    def initialize
      @options = {}

      if block_given?
        yield self
      end
    end

    attr_reader :options

    def gui?
      !!options[:gui]
    end

    def target_user
      @target_user ||= begin
        target_user = options[:user] || profile
        unless target_user.start_with?('br-')
          target_user = "br-#{target_user}"
        end
        target_user
      end
    end

    def run
      report_exceptions do
        process_args
        launch
      end
    end

    private

    def report_exceptions
      yield
    rescue => exc
      if gui?
        Utils.run(['yad', '--title', 'Error launching browser',
          '--text', "#{exc.class}: #{exc}",
          '--button', 'OK'])
        # TODO fallback to zenity if it is available and yad is not.
        exit 1
      else
        raise
      end
    end

    def maybe_relaunch_as_target_user
      if Etc.getpwuid(Process.euid).name != target_user
        begin
          Etc.getpwnam(target_user)
        rescue ArgumentError => e
          if e.message =~ /can't find user/
            if options[:user]
              # User was explicitly requested
              raise
            else
              # Ignore
            end
          else
            raise
          end
        else
          puts "Relaunching as #{target_user}"
          cmd = ['sudo', '-nu', target_user, 'id']
          Utils.run(cmd)
          auths = `xauth list`.strip.split("\n")
          auths.each do |auth|
            cmd = ['sudo', '-nu', target_user,
              'env', "XAUTHORITY=/home/#{target_user}/.Xauthority",
              'xauth', 'add'] + auth.split(/\s+/)
            Utils.run(cmd)
          end
          cmd = [
            'sudo', '-nu', target_user,
            'env', "XAUTHORITY=/home/#{target_user}/.Xauthority",
            File.realpath(File.expand_path($0))
          ] + build_cmd
          puts "Executing #{cmd.join(' ')}"
          exec(*cmd)
        end
      end
    end

    def run_browser(cmd)
      joined = cmd.join(' ')
      puts "Executing #{joined}"
      if pid = fork
        if options[:group_accessible]
          Thread.new do
            sleep 2
            begin
              FileUtils.chmod_R('g+rwX', profile_path)
            rescue SystemCallError => exc
              warn "Error chmodding profile dir: #{exc.class}: #{exc}"
            end
            loop do
              puts 'chmod'
              begin
                FileUtils.chmod_R('g+rwX', profile_path)
              rescue SystemCallError => exc
                warn "Error chmodding profile dir: #{exc.class}: #{exc}"
              end
              sleep 5
            end
          end
        end

        Process.wait(pid)
        if $?.exitstatus != 0
          raise "Failed to run #{joined}: process exited with code #{$?.exitstatus}"
        end
      else
        exec(*cmd)
      end
    end

  end
end
