require "bosh_workstation_cpi/virtualbox/error"
require "bosh_workstation_cpi/virtualbox/vm"

module BoshWorkstationCpi::Virtualbox
  class VmFinder
    def initialize(driver, logger=Logger.new(STDERR))
      @driver = driver
      @logger = logger
    end

    def find(uuid, options={})
      exit_code, _ = @driver.execute_raw("showvminfo", uuid)

      if exit_code.zero?
        Vm.new(@driver, uuid, @logger)
      elsif options[:raise] != false
        raise BoshWorkstationCpi::Virtualbox::Error, \
          "Failed to find VM with '#{uuid}'"
      end
    end
  end
end
