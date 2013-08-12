module BoshWorkstationCpi::Virtualbox
  class CdromMounter
    def initialize(driver, vm, logger=Logger.new(STDERR))
      @driver = driver
      @vm = vm
      @logger = logger
    end

    def mount(iso_path)
      @logger.debug("virtualbox.cdrom_mounter.#{__method__} iso_path=#{iso_path}")
      @driver.execute(
        "storageattach", @vm.uuid,
        "--storagectl",  "IDE Controller",
        "--port",        "1",
        "--device",      "0",
        "--type",        "dvddrive",
        "--medium",      iso_path,
      )
    end

    def unmount
      @logger.debug("virtualbox.cdrom_mounter.#{__method__}")
      @driver.execute(
        "storageattach", @vm.uuid,
        "--storagectl",  "IDE Controller",
        "--port",        "1",
        "--device",      "0",
        "--type",        "dvddrive",
        "--medium",      "none", # removes
      )
    end
  end
end
