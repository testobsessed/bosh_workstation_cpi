module BoshWorkstationCpi::Actions
  class AttachDisk
    # @param [String] vm vm id that was once returned by {#create_vm}
    # @param [String] disk disk id that was once returned by {#create_disk}
    def initialize(vm_manager, disk_manager, vm_id, disk_id, type, logger=Logger.new(STDERR))
      @vm_manager = vm_manager
      @disk_manager = disk_manager
      @vm_id = vm_id
      @disk_id = disk_id

      raise ArgumentError, "type is unknown" \
        unless %w(ephemeral persistent).include?(type)
      @type = type

      @logger = logger
    end

    def run
      vm = check_vm
      check_disk
      power_off(vm)
      port      = attach_disk(vm)
      agent_env = rebuild_agent_env(vm, port)
      mount_cdrom_with_agent_env(vm, agent_env)
      power_on(vm)
    end

    private

    def check_vm
      @logger.info("Checking vm '#{@vm_id}'")
      @vm_manager.driver.vm_finder.find(@vm_id)
    end

    def check_disk
      @logger.info("Checking disk '#{@disk_id}'")
      raise "Could not find disk #{@disk_id}" \
        unless @disk_manager.exists?(@disk_id)
    end

    def power_off(vm)
      @logger.info("Powering off vm '#{vm.uuid}'")
      vm.halt if vm.running?
    end

    def attach_disk(vm)
      @logger.info("Attaching disk '#{@disk_id}' to vm '#{vm.uuid}'")

      disk_attacher = @vm_manager.driver.disk_attacher(vm)
      port_and_device = disk_attacher.attach(@disk_manager.path(@disk_id))

      contents = JSON.dump(port_and_device)
      @vm_manager.create_artifact(vm.uuid, "#{@disk_id}-disk-attachment.json", contents)
      port_and_device.first
    end

    def rebuild_agent_env(vm, port)
      @logger.info("Rebuilding agent env for #{vm.uuid} with #{@disk_id}")
      contents = @vm_manager.get_artifact(vm.uuid, "env.json")
      BoshWorkstationCpi::AgentEnv.from_json(contents).tap do |env|
        env.send("add_#{@type}_disk", @disk_id, port)
      end
    end

    def mount_cdrom_with_agent_env(vm, agent_env)
      @logger.info("Mounting CDROM with updated agent env")

      @vm_manager.create_artifact(vm.uuid, "env.json", agent_env.as_json)
      @vm_manager.create_artifact(vm.uuid, "env.iso", agent_env.as_iso)

      @vm_manager.driver.cdrom_mounter(vm).tap do |cdrom|
        cdrom.unmount
        cdrom.mount(@vm_manager.artifact_path(vm.uuid, "env.iso"))
      end
    end

    def power_on(vm)
      @logger.info("Powering on vm '#{vm.uuid}'")
      vm.start
      sleep(120)
    end
  end
end
