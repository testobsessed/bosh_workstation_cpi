module BoshWorkstationCpi::Actions
  class DeleteVm
    # @param [String] vm vm id that was once returned by {#create_vm}
    def initialize(vm_manager, vm_id, logger=Logger.new(STDERR))
      @vm_manager = vm_manager
      @vm_id = vm_id
      @logger = logger
    end

    def run
      vm = check_vm
      delete_vm(vm)
    end

    private

    def check_vm
      @logger.info("Checking vm '#{@vm_id}'")
      @vm_manager.driver.vm_finder.find(@vm_id)
    end

    def delete_vm(vm)
      @logger.info("Deleting vm '#{vm.uuid}'")
      vm.halt
      vm.delete
      @vm_manager.delete(vm.uuid)
    end
  end
end
