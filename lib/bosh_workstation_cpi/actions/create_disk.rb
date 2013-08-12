module BoshWorkstationCpi::Actions
  class CreateDisk
    # @param [Integer] size disk size in MB
    # @param [optional, String] vm_locality vm id if known of the VM that this disk will be attached to
    def initialize(disk_manager, size, vm_locality, logger=Logger.new(STDERR))
      @disk_manager = disk_manager

      raise ArgumentError, "size must be > 0" \
        unless size > 0
      @size = size

      @vm_locality = vm_locality
      @logger = logger
    end

    # @returns [String] opaque id later used by {#attach_disk}, {#detach_disk}, and {#delete_disk}
    def run
      disk_id = create_disk
      allocate_disk(disk_id)
      disk_id
    end

    private

    def create_disk
      @logger.info("Creating disk")
      @disk_manager.create
    end

    def allocate_disk(disk_id)
      @logger.info("Allocating disk '#{disk_id}'")
      disk_creator = @disk_manager.driver.disk_creator
      disk_creator.create(@disk_manager.path(disk_id), @size)
    end
  end
end
