require "bosh_workstation_cpi/virtualbox/error"

module BoshWorkstationCpi::Virtualbox
  class Vm
    attr_reader :uuid

    def initialize(driver, uuid, logger=Logger.new(STDERR))
      @driver = driver
      raise ArgumentError, "uuid must not be nil" \
        unless @uuid = uuid
      @logger = logger
    end

    def start
      @logger.debug("virtualbox.vm.#{__method__}")
      mode = ENV["BOSH_VAGRANT_CPI_GUI"] ? "gui" : "headless"
      exit_code, output = @driver.execute_raw("startvm", @uuid, "--type", mode)

      if exit_code == 0
        return true
      elsif output =~ /VM ".+?" has been successfully started/
        return true
      else
        raise BoshWorkstationCpi::Virtualbox::Error, \
          "Failed to start VM '#{@uuid}'"
      end
    end

    def mac_address
      @logger.debug("virtualbox.vm.#{__method__}")
      output = @driver.execute("showvminfo", @uuid, "--machinereadable")
      output.split("\n").each do |line|
        return $1.to_s if line =~ /^macaddress1="(.+?)"$/
      end
      nil
    end

    def state
      @logger.debug("virtualbox.vm.#{__method__}")
      output = @driver.execute("showvminfo", @uuid, "--machinereadable")
      if output =~ /^name="<inaccessible>"$/
        :inaccessible
      elsif output =~ /^VMState="(.+?)"$/
        $1.to_sym
      end
    end

    def running?
      @logger.debug("virtualbox.vm.#{__method__}")
      state == :running
    end

    def name=(name)
      @logger.debug("virtualbox.vm.#{__method__} name=#{name}")
      @driver.execute("modifyvm", @uuid, "--name", name)
    end

    def halt
      @logger.debug("virtualbox.vm.#{__method__}")
      @driver.execute("controlvm", @uuid, "poweroff")
    end

    def delete
      @logger.debug("virtualbox.vm.#{__method__}")
      @driver.execute("unregistervm", @uuid, "--delete")
    end

    def enable_host_only_adapter
      @driver.execute(
        "modifyvm",           @uuid,
        "--nic1",             "hostonly",
        "--hostonlyadapter1", "vboxnet0",
      )
    end
  end
end
