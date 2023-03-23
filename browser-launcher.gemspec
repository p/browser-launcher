# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "seriamp"
  spec.version       = '0.1.0'
  spec.authors       = ['Oleg Pudeyev']
  spec.email         = ['code@olegp.name']
  spec.summary       = %q{Browser Launcher}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/p/browser-launcher"
  spec.license       = "BSD-2-Clause"

  spec.files         = `git ls-files -z`.split("\x0").reject { |path| path.start_with?('docs/') }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_runtime_dependency 'activesupport', '~> 6.0'
end
