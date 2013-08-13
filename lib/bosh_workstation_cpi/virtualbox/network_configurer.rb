module BoshWorkstationCpi::Virtualbox
  class NetworkConfigurer
    def initialize(driver, vm, logger)
      @driver = driver
      @vm = vm
      @logger = logger
    end

    def configure(network_names)
      @logger.debug("virtualbox.network_configurer.#{__method__} " + 
        "network_names=#{network_names.inspect}")
      strategy = configure_strategy
      build_nic_to_name(network_names).each do |nic, name|
        name ? strategy.set_nic(nic, name) : strategy.unset_nic(nic)
      end
    end

    def macs(network_names)
      @logger.debug("virtualbox.network_configurer.#{__method__} " + 
        "network_names=#{network_names.inspect}")
      nic_to_name = build_nic_to_name(network_names)
      nic_to_mac  = read_nic_to_macs
      Hash[nic_to_name.map { |nic, name| [name, nic_to_mac[nic]] }]
    end

    private

    # https://0-forums.virtualbox.org.ilsprod.lib.neu.edu/viewtopic.php?f=1&t=53762
    def configure_strategy
      strategy = @vm.running? ? ForRunningVm : ForPoweredOffVm
      strategy.new(@driver, @vm, @logger)
    end

    # Attaching NICs to running VM is not allowed,
    # so 4 NICs will always be connected.
    MAX_NICS = 4

    # Establish consistent order of nic # to network names.
    def build_nic_to_name(network_names)
      raise ArgumentError, "Exceeded # of NICs (#{MAX_NICS})" \
        if network_names.size > MAX_NICS

      normalized = network_names.sort
      raise ArgumentError, "Duplicate network name is not allowed" \
        unless normalized.uniq == normalized

      Hash[(1..MAX_NICS).zip(normalized)]
    end

    def read_nic_to_macs
      @logger.debug("virtualbox.network_configurer.#{__method__}")
      macs = {}
      output = @driver.execute("showvminfo", @vm.uuid, "--machinereadable")
      output.split("\n").each do |line|
        if matcher = /^macaddress(\d+)="(.+?)"$/.match(line)
          macs[matcher[1].to_i] = matcher[2].to_s
        end
      end
      macs
    end

    class ForPoweredOffVm
      def initialize(*args)
        @driver, @vm, @logger = args
      end

      def set_nic(nic, network_name)
        @logger.debug("virtualbox.network_configurer.whenoff.#{__method__} " + 
          "nic=#{nic} network_name=#{network_name}")
        @driver.execute(
          "modifyvm",                @vm.uuid,
          "--nic#{nic}",             "hostonly",
          "--hostonlyadapter#{nic}", network_name,
        )
      end

      def unset_nic(nic)
        @logger.debug("virtualbox.network_configurer.whenoff.#{__method__} nic=#{nic}")
        @driver.execute("modifyvm", @vm.uuid, "--nic#{nic}", "null")
      end
    end

    class ForRunningVm
      def initialize(*args)
        @driver, @vm, @logger = args
      end

      def set_nic(nic, network_name)
        @logger.debug("virtualbox.network_configurer.whenon.#{__method__} " + 
          "nic=#{nic} network_name=#{network_name}")
        @driver.execute("controlvm", @vm.uuid, "nic#{nic}", "hostonly", network_name)
      end

      def unset_nic(nic)
        @logger.debug("virtualbox.network_configurer.whenon.#{__method__} nic=#{nic}")
        @driver.execute("controlvm", @vm.uuid, "nic#{nic}", "null")
      end
    end
  end
end
