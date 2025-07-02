autoload :Etc, 'etc'
autoload :Timeout, 'timeout'

module BrowserLauncher
  module Utils

    class SpawnedProcessErrorExit < StandardError
      def initialize(cmd, exitstatus)
        @cmd = cmd
        @exitstatus = exitstatus
        message = "Failed to run #{cmd}: process exited with code #{exitstatus}"
        super(message)
      end

      attr_reader :cmd
      attr_reader :exitstatus
    end

    module_function def run(cmd, stdin_contents: nil, stdout: nil, timeout: nil, &block)
      joined = cmd.join(' ')
      puts "Executing #{joined}"

      # TODO temporary
      #stdin_contents = stdin

      stdin = nil
      if stdin_contents
        stdin_rd, stdin_wr = IO.pipe
        stdin_io = stdin_rd
        stdin_wr.close_on_exec = true
      end

      if stdout == :return || stdout == :yield
        stdout_rd, stdout_wr = IO.pipe
        stdout_io = stdout_wr
        stdout_rd.close_on_exec = true
        stdout_buf = ''
      end

      opts = {
        in: stdin_io&.fileno,
        out: stdout_io&.fileno,
      }.compact

      pid = Process.spawn(*cmd, **opts)
      threads = []

      if stdin_contents
        stdin_rd.close

        threads << Thread.new do
          stdin_wr << stdin_contents
          stdin_wr.close
        end
      end

      if stdout_io
        stdout_wr.close

        threads << Thread.new do
          while chunk = stdout_rd.read(1024)
            if stdout == :yield
              block.call(chunk)
            else
              stdout_buf << chunk
            end
          end
        end
      end

      if timeout
        begin
          Timeout.timeout(timeout, Timeout::Error, "Timed out (#{timeout} seconds) waiting for #{cmd}") do
            Process.wait(pid)
          end
        rescue Timeout::Error
          Process.kill('TERM', pid) rescue nil
          Thread.new do
            sleep 1
            Process.kill('KILL', pid) rescue nil
          end
          raise
        end
      else
        Process.wait(pid)
      end

      threads.map(&:kill)
      threads.map(&:join)

      if $?.exitstatus != 0
        raise SpawnedProcessErrorExit.new(joined, $?.exitstatus)
      end

      if stdout == :return
        stdout_buf
      else
        nil
      end
    end

    module_function def run_stdout(cmd, timeout: nil, &block)
      return run(cmd, timeout: timeout,
        stdout: block_given? ? :yield : :return, &block)
    end

    module_function def verify_path_exists(path, desc, force: false)
      unless File.exist?(path)
        raise "Specified #{desc} does not exist: #{path}"
      end
      path
    end

    module_function def check_or_filter_paths(paths, desc, force: false, gui: false)
      paths&.map do |path|
        if File.exist?(path)
          path
        else
          if force
            title = 'Requested componentmissing'
            msg = "#{desc} path does not exist: #{path}, removing"
            warning(title, msg, gui: gui)
            nil
          else
            title = 'Requested component missing'
            msg = "#{desc} path does not exist: #{path}"
            error(title, msg, gui: gui)
          end
        end
      end&.compact
    end

    module_function def report_errors
      yield
    rescue => exc
      if gui?
        gui_msg('Error launching browser', "#{exc.class}: #{exc}")
        exit 1
      else
        raise
      end
    end

    module_function def warning(title, msg, gui:)
      if gui
        gui_msg(title, msg)
      else
        warn(msg)
      end
    end

    module_function def error(title, msg, gui:)
      if gui
        gui_msg(title, msg)
        exit 1
      else
        raise msg
      end
    end

    module_function def gui_msg(title, text)
      run(['yad', '--title', title,
        '--text', text,
        '--button', 'OK'])
    rescue SpawnedProcessErrorExit => exc
      # When message box is dismissed via Esc, process exit status is 252
      if exc.exitstatus == 252
        # Silence
      else
        raise
      end
    end

    module_function def monotime
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    module_function def current_user
      Etc.getpwuid(Process.euid).name
    end

    module_function def reexec_as_user(target_user, xauth: false)
      if xauth
        cmd = ['sudo', '-nu', target_user, 'id']
        Utils.run(cmd)
        auth = Utils.run_stdout(
          ['xauth', 'extract', '-', ENV.fetch('DISPLAY')],
          timeout: 3)
        cmd = ['sudo', '-nu', target_user,
          'env', "XAUTHORITY=/home/#{target_user}/.Xauthority",
          'xauth', 'merge', '-']
        Utils.run(cmd, stdin_contents: auth, timeout: 3)
        extra_args = [
          'env', "XAUTHORITY=#{target_xauthority_path}",
        ]
      else
        extra_args = []
      end

      puts "Relaunching as #{target_user}"
      cmd = [
        'sudo', '-nu', target_user,
      ] + extra_args + [
        File.realpath(File.expand_path($0))
      ] + ARGV
      puts "Executing #{cmd.join(' ')}"
      exec(*cmd)
    end

    module_function def dir_entries(path)
      Dir.entries(path).reject do |entry|
        entry == '.' || entry == '..'
      end.sort
    end

  end
end
