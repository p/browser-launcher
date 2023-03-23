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

    module_function def verify_path_exists(path, desc)
      unless File.exist?(path)
        raise "Specified #{desc} does not exist: #{path}"
      end
      path
    end

  end
end
