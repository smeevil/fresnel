require "rake"
require "rake/clean"
require "rake/gempackagetask"
require 'rubygems'

################################################################################
### Gem
################################################################################

begin
  # Parse gemspec using the github safety level.
  file = Dir['*.gemspec'].first
  data = File.read(file)
  spec = nil
  # FIXME: Lowered SAFE from 3 to 2 to work with Ruby 1.9 due to rubygems
  # performing a require internally
  Thread.new { spec = eval("$SAFE = 2\n%s" % data)}.join

  # Create the gem tasks
  Rake::GemPackageTask.new(spec) do |package|
    package.gem_spec = spec
  end
rescue Exception => e
  printf "WARNING: Error caught (%s): %s\n%s", e.class.name, e.message, e.backtrace[0...5].map {|l| '  %s' % l}.join("\n")
end

desc 'Package and install the gem for the current version'
task :install => :gem do
  system "sudo gem install -l pkg/%s-%s.gem" % [spec.name, spec.version]
end

desc 'Show files missing from gemspec'
task :diff do
  files = %w[
    Rakefile
    *README* *readme*
    *LICENSE*
    *.gemspec deps.rip
    bin/*
    lib/**/*
    spec/**/*
  ].map {|pattern| Dir.glob(pattern)}.flatten.select{|f| File.file?(f)}
  missing_files = files - spec.files
  extra_files = spec.files - files
  puts "Missing files:"
  puts missing_files.join(" ")
  puts "Extra files:"
  puts extra_files.join(" ")
end

desc 'Local install the latest gem version'
task :reinstall do
  system("rm -f pkg/*.gem && rake gem && gem install pkg/*.gem")
end

desc 'Uninstall all Fresnel versions and install the latest gem version'
task :upgrade do
  system("gem uninstall -a -x fresnel && rm -f pkg/*.gem && rake gem && gem install pkg/*.gem")
end