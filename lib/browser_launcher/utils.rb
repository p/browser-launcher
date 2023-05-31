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

    module_function def run(cmd, stdout: nil)
      joined = cmd.join(' ')
      puts "Executing #{joined}"

      pid = fork do
        if stdout
          STDOUT.reopen(stdout)
        end
        exec(*cmd)
      end

      Process.wait(pid)
      if $?.exitstatus != 0
        raise SpawnedProcessErrorExit.new(joined, $?.exitstatus)
      end
    end

    module_function def run_stdout(cmd)
      joined = cmd.join(' ')
      rd, wr = IO.pipe
      puts "Executing #{joined}"

      pid = fork do
        rd.close
        STDOUT.reopen(wr)
        wr.close
        exec(*cmd)
      end

      wr.close
      while chunk = rd.read(1000)
        yield chunk
      end

      Process.wait(pid)
      if $?.exitstatus != 0
        raise SpawnedProcessErrorExit.new(joined, $?.exitstatus)
      end
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

  end
end
