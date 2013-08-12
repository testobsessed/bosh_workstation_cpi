module BoshWorkstationCpi::Actions
  class ConfigureNetworks
    # @param [String] vm vm id that was once returned by {#create_vm}
    # @param [Hash] networks list of networks and their settings needed for this VM,
    #               same as the networks argument in {#create_vm}
    def initialize(vm_id, networks)
      @vm_id = vm_id
      @networks = networks
    end

    def run
      raise "configure_networks CPI is not implemented"
    end
  end
end
