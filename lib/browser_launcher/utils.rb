module BrowserLauncher
  module Utils

    module_function def run(cmd)
      joined = cmd.join(' ')
      puts "Executing #{joined}"
      if pid = fork
        Process.wait(pid)
        if $?.exitstatus != 0
          raise "Failed to run #{joined}: process exited with code #{$?.exitstatus}"
        end
      else
        exec(*cmd)
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
    end

    module_function def monotime
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

  end
end
