version = "0.0.1"

Gem::Specification.new do |s|
  s.name = "bosh_workstation_cpi"
  s.summary = "BOSH Workstation CPI"
  s.description = s.summary
  
  s.author = "cppforlife"
  s.email  = "cppforlife@gmail.com"
  s.homepage = "https://github.com/cppforlife/bosh_workstation_cpi"

  s.version  = version
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  s.bindir = "bin"
  s.executables = %w(
    bosh_workstation_cpi_set_up
    bosh_workstation_cpi_inject
    bosh_workstation_cpi_switch
  )

  # This gem specification is copied onto MicroBOSH director;
  # hence, it should act as a processed gemspec.
  if File.directory?("/var/vcap")
    s.require_path = "lib"
    s.files = s.executables.map { |e| "bin/#{e}" }
  else
    s.require_path = "lib"
    s.files = `git ls-files -- lib/*`.split("\n") + %w(README.md)
  end
end
