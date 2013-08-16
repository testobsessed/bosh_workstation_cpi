require "bosh_workstation_cpi/cpi_options"
require "bosh_workstation_cpi/runners"
require "bosh_workstation_cpi/virtualbox"
require "bosh_workstation_cpi/managers"
require "bosh_workstation_cpi/actions"

module BoshWorkstationCpi
  class Cpi
    def self.default_logger
      if defined?(Bosh::Clouds::Config)
        Bosh::Clouds::Config.logger 
      else
        Logger.new(STDERR)
      end
    end

    def initialize(options, logger=nil)
      @logger  = logger || self.class.default_logger
      @options = CpiOptions.from_vsphere(options, @logger)

      if @options.local_access?
        runner = Runners::Local.new(@logger)
      else
        runner = Runners::Remote.new(
          @options.host,
          @options.user,
          @options.password,
          @logger,
        )
      end

      driver = Virtualbox::Driver.new(runner, @logger)

      @stemcell_manager = Managers::Stemcell.new(
        @options.stemcells_dir, runner, driver, @logger)
      @vm_manager = Managers::Vm.new(
        @options.vms_dir, runner, driver, @logger)
      @disk_manager = Managers::Disk.new(
        @options.disks_dir, runner, driver, @logger)
    end

    def create_stemcell(*args)
      Actions::CreateStemcell.new(
        @stemcell_manager, *args, @logger).run
    end

    def delete_stemcell(*args)
      Actions::DeleteStemcell.new(
        @stemcell_manager, *args, @logger).run
    end

    def create_vm(agent_id, stemcell_id, resource_pool,
                  networks, disk_locality=nil, env=nil)
      vm_id = Actions::CreateVm.new(
        @stemcell_manager, @vm_manager, @options.agent, 
        agent_id, stemcell_id, resource_pool, 
        networks, disk_locality, env, @logger,
      ).run

      disk_id = Actions::CreateDisk.new(
        @disk_manager, resource_pool["disk"], nil, @logger).run

      # create_vm CPI action *must* attach ephemeral disk
      # *before* powering on VM, otherwise, bosh_agent
      # will not properly bootstrap environment.
      Actions::AttachDisk.new(
        @vm_manager, @disk_manager, 
        vm_id, disk_id, "ephemeral", @logger,
      ).run

      Actions::RebootVm.new(
        @vm_manager, vm_id, @logger).run

      vm_id
    end

    def delete_vm(*args)
      Actions::DeleteVm.new(@vm_manager, *args, @logger).run
    end

    def has_vm?(*args)
      Actions::HasVm.new(@vm_manager, *args, @logger).run
    end

    def reboot_vm(*args)
      Actions::RebootVm.new(@vm_manager, *args, @logger).run
    end

    def set_vm_metadata(*args)
      Actions::SetVmMetadata.new(@vm_manager, *args, @logger).run
    end

    def configure_networks(*args)
      Actions::ConfigureNetworks.new(*args).run
    end

    def create_disk(*args)
      Actions::CreateDisk.new(@disk_manager, *args, @logger).run
    end

    def delete_disk(*args)
      Actions::DeleteDisk.new(@disk_manager, *args, @logger).run
    end

    def attach_disk(*args)
      Actions::AttachDisk.new(
        @vm_manager, @disk_manager, *args, "persistent", @logger).run
    end

    def detach_disk(*args)
      Actions::DetachDisk.new(
        @vm_manager, @disk_manager, *args, "persistent", @logger).run
    end

    # List the attached disks of the VM.
    # @param [String] vm_id is the CPI-standard vm_id (eg, returned from current_vm_id)
    # @return [array[String]] list of opaque disk_ids that can be used with the
    #                         other disk-related methods on the CPI
    def get_disks(vm_id)
      not_implemented(:get_disks)
    end

    # Get the vm_id of this host
    # @return [String] opaque id later used by other methods of the CPI
    def current_vm_id
      not_implemented(:current_vm_id)
    end

    # Take snapshot of disk
    # @param [String] disk_id disk id of the disk to take the snapshot of
    # @return [String] snapshot id
    def snapshot_disk(disk_id, metadata={})
      not_implemented(:snapshot_disk)
    end

    # Delete a disk snapshot
    # @param [String] snapshot_id snapshot id to delete
    def delete_snapshot(snapshot_id)
      not_implemented(:delete_snapshot)
    end

    # Validates the deployment
    # @api not_yet_used
    def validate_deployment(old_manifest, new_manifest)
      not_implemented(:validate_deployment)
    end

    private

    def not_implemented(method)
      raise NotImplemented, "`#{method}' is not implemented by #{self.class}"
    end
  end
end
