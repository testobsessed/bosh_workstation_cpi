module BoshWorkstationCpi::Virtualbox
  class DiskCreator
    def initialize(driver, logger=Logger.new(STDERR))
      @driver = driver
      @logger = logger
    end

    def create(path, size_in_mb)
      @logger.debug("virtualbox.disk_creator.#{__method__} " + 
        "path=#{path} size_in_mb=#{size_in_mb}")
      @driver.execute(
        "createhd",
        "--filename", "#{path}/disk.vmdk",
        "--size",     size_in_mb.to_s,
        "--format",   "VMDK",
        "--variant",  "Standard",
      )
    end
  end
end
