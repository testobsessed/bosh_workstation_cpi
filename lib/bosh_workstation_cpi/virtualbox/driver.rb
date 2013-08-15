require "shellwords"
require "bosh_workstation_cpi/virtualbox/error"
require "bosh_workstation_cpi/virtualbox/vm_importer"
require "bosh_workstation_cpi/virtualbox/vm_finder"
require "bosh_workstation_cpi/virtualbox/cdrom_mounter"
require "bosh_workstation_cpi/virtualbox/disk_attacher"
require "bosh_workstation_cpi/virtualbox/disk_creator"
require "bosh_workstation_cpi/virtualbox/resume_pause_hot_plugger"

module BoshWorkstationCpi::Virtualbox
  class Driver
    def initialize(runner, logger)
      @runner = runner
      @logger = logger
    end

    def execute_raw(*cmd_pieces)
      @runner.execute("VBoxManage", *cmd_pieces)
    end

    def execute(*args)
      exit_code, output = execute_raw(*args)

      if exit_code != 0
        if exit_code == 126
          # This exit code happens if VBoxManage is on the PATH,
          # but another executable it tries to execute is missing.
          # This is usually indicative of a corrupted VirtualBox install.
          raise BoshWorkstationCpi::Virtualbox::Error, \
            "Most likely corrupted VirtualBox installation"
        else
          errored = true
        end
      else
        # Sometimes, VBoxManage fails but doesn't actual return a non-zero exit code.
        if output =~ /failed to open \/dev\/vboxnetctl/i
          # This catches an error message that only shows when kernel
          # drivers aren't properly installed.
          raise BoshWorkstationCpi::Virtualbox::Error, \
            "Error message about vboxnetctl"
        end

        if output =~ /VBoxManage: error:/
          @logger.info("VBoxManage error text found, assuming error.")
          errored = true
        end
      end

      if errored
        raise BoshWorkstationCpi::Virtualbox::Error, <<-MSG
          Error executing command:
            Command:   '#{args.inspect}'
            Exit code: '#{exit_code}'
            Output:    '#{output}'
        MSG
      end

      output.gsub("\r\n", "\n")
    end

    def vm_importer
      VmImporter.new(self, @logger)
    end

    def vm_finder
      VmFinder.new(self, @logger)
    end

    def cdrom_mounter(vm)
      CdromMounter.new(self, vm, resume_pause_hot_plugger(vm), @logger)
    end

    def disk_creator
      DiskCreator.new(self, @logger)
    end

    def disk_attacher(vm)
      DiskAttacher.new(self, vm, resume_pause_hot_plugger(vm), @logger)
    end

    private

    def resume_pause_hot_plugger(vm)
      ResumePauseHotPlugger.new(self, vm, @logger)
    end
  end
end
