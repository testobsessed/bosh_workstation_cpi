require "bosh_workstation_cpi/virtualbox/error"
require "bosh_workstation_cpi/virtualbox/vm"

module BoshWorkstationCpi::Virtualbox
  class VmImporter
    def initialize(driver, logger=Logger.new(STDERR))
      @driver = driver
      @logger = logger
    end

    def import(ovf_path)
      output = @driver.execute("import", ovf_path)
      if output !~ /Suggested VM name "(.+?)"/
        raise BoshWorkstationCpi::Virtualbox::Error, \
          "Couldn't find VM name in the output"
      end

      name = $1.to_s
      output = @driver.execute("list", "vms")
      if output =~ /^"#{Regexp.escape(name)}" \{(.+?)\}$/
        return Vm.new(@driver, $1.to_s, @logger)
      end

      raise BoshWorkstationCpi::Virtualbox::Error, \
        "Failed to import #{ovf_path}"
    end
  end
end
