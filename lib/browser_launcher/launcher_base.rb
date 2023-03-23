module BrowserLauncher
  class LaunchBase
    def initialize
      @options = {}

      if block_given?
        yield self
      end
    end

    def run
      report_exceptions do
        process_args
        launch
      end
    end

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
  end
end
