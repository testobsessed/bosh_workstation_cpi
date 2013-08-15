require "bosh_workstation_cpi/virtualbox/error"
require "bosh_workstation_cpi/virtualbox/vm"

module BoshWorkstationCpi::Virtualbox
  class VmImporter
    def initialize(driver, logger)
      @driver = driver
      @logger = logger
    end

    def import(ovf_path)
      retry_times do
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

    private

    def retry_times(times=10, sleep=5, &blk)
      blk.call
    rescue BoshWorkstationCpi::Virtualbox::Error => e
      times -= 1
      if times.zero?
        @logger.info("virtualbox.vm_importer.retry.failed error=#{e.inspect}")
        raise
      else
        @logger.info("virtualbox.vm_importer.retry try=#{times}")
        sleep(sleep)
        retry
      end
    end
  end
end
