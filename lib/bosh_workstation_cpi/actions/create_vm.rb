require "bosh_workstation_cpi/agent_env"
require "bosh_workstation_cpi/virtualbox"

module BoshWorkstationCpi::Actions
  class CreateVm
    # Creates a VM - creates (and powers on) a VM from a stemcell with the proper resources
    # and on the specified network. When disk locality is present the VM will be placed near
    # the provided disk so it won't have to move when the disk is attached later.
    #
    # Sample networking config:
    #  {"network_a" =>
    #    {
    #      "netmask"          => "255.255.248.0",
    #      "ip"               => "172.30.41.40",
    #      "gateway"          => "172.30.40.1",
    #      "dns"              => ["172.30.22.153", "172.30.22.154"],
    #      "cloud_properties" => {"name" => "VLAN444"}
    #    }
    #  }
    #
    # Sample resource pool config (CPI specific):
    #  {
    #    "ram"  => 512,
    #    "disk" => 512,
    #    "cpu"  => 1
    #  }
    # or similar for EC2:
    #  {"name" => "m1.small"}
    #
    # @param [String] agent_id UUID for the agent that will be used later on by the director
    #                 to locate and talk to the agent
    # @param [String] stemcell_id stemcell id that was once returned by {#create_stemcell}
    # @param [Hash] resource_pool cloud specific properties describing the resources needed
    #               for this VM
    # @param [Hash] networks list of networks and their settings needed for this VM
    # @param [optional, String, Array] disk_locality disk id(s) if known of the disk(s) that will be
    #                                  attached to this vm
    # @param [optional, Hash] env environment that will be passed to this vm
    def initialize(stemcell_manager, vm_manager, agent_options, 
                   agent_id, stemcell_id, resource_pool, 
                   networks, disk_locality=nil, env=nil, logger)
      @stemcell_manager = stemcell_manager
      @vm_manager = vm_manager
      @agent_options = agent_options
      @agent_id = agent_id
      @stemcell_id = stemcell_id
      @resource_pool = resource_pool
      @networks = networks
      @disk_locality = disk_locality
      @env = env
      @logger = logger
    end

    def run
      check_stemcell
      vm        = create_vm
      agent_env = build_agent_env(vm)
      mount_cdrom_with_agent_env(vm, agent_env)
      power_on(vm)
      vm.uuid
    rescue Exception => e
      clean_up_partial_vm(vm)
      raise
    end

    private

    def check_stemcell
      @logger.info("Checking stemcell '#{@stemcell_id}'")
      raise "Could not find stemcell #{@stemcell_id}" \
        unless @stemcell_manager.exists?(@stemcell_id)
    end

    def create_vm
      @logger.info("Creating VM")
      stemcell_path = @stemcell_manager.path(@stemcell_id)

      importer = @vm_manager.driver.vm_importer
      importer.import("#{stemcell_path}/image.ovf").tap do |vm|
        vm.name = "vm-#{vm.uuid}"
        vm.enable_host_only_adapter
      end
    end

    def build_agent_env(vm)
      @logger.info("Building agent env for '#{vm.uuid}'")
      BoshWorkstationCpi::AgentEnv.new.tap do |env|
        env.vm_id = vm.uuid
        env.name = vm.uuid
        env.env = @env
        env.agent_id = @agent_id
        env.agent_env = @agent_options
        env.add_network_with_mac(@networks, vm.mac_address)
        env.add_disks
      end
    end

    def mount_cdrom_with_agent_env(vm, agent_env)
      @logger.info("Mounting CDROM with agent env")

      @vm_manager.create_artifact(vm.uuid, "env.json", agent_env.as_json)
      @vm_manager.create_artifact(vm.uuid, "env.iso", agent_env.as_iso)

      cdrom = @vm_manager.driver.cdrom_mounter(vm)
      cdrom.mount(@vm_manager.artifact_path(vm.uuid, "env.iso"))
    end

    def power_on(vm)
      @logger.info("Powering on vm '#{vm.uuid}'")
      vm.start
    end

    def clean_up_partial_vm(vm)
      return unless vm
      vm.delete
      @vm_manager.delete(vm.uuid) if vm.uuid
    end
  end
end
