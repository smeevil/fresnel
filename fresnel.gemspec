Gem::Specification.new do |s|
  # Project
  s.name         = 'fresnel'
  s.summary      = "Fresnel is a console manager to LighthouseApp.com using the official lighthouse api."
  s.description  = s.summary
  s.version      = '0.5.1'
  s.date         = '2009-12-03'
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Gerard de Brieder", "Wes Oldenbeuving"]
  s.email        = "smeevil@gmail.com"
  s.homepage     = "http://www.github.com/smeevil/fresnel"

  # Files
  root_files     = %w[README.markdown Rakefile fresnel.gemspec]
  bin_files      = %w[fresnel]
  fresnel_files  = %w[cache cli color date_parser frame lighthouse setup_wizard]
  lib_files      = %w[fresnel] + fresnel_files.map {|f| "fresnel/#{f}"}
  s.bindir       = "bin"
  s.require_path = "lib"
  s.executables  = bin_files
  s.test_files   = []
  s.files        = root_files + s.test_files + bin_files.map {|f| 'bin/%s' % f} + lib_files.map {|f| 'lib/%s.rb' % f}

  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = %w[ README.markdown]
  s.rdoc_options << '--inline-source' << '--line-numbers' << '--main' << 'README.rdoc'

  # Dependencies
  s.add_dependency 'activesupport', ">= 2.3.0"
  s.add_dependency 'terminal-table', ">= 1.3.0"
  s.add_dependency 'highline', ">= 1.5.1"

  # Requirements
  s.required_ruby_version = ">= 1.8.0"
end
