# frozen_string_literal: true

require 'browser_launcher/fox/packed_extension'
require 'browser_launcher/fox/unpacked_extension'

module BrowserLauncher
  module Fox
    module Extension
      module_function def new(path)
        if File.directory?(path)
          UnpackedExtension.new(path)
        else
          PackedExtension.new(path)
        end
      end
    end
  end
end
