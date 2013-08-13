require "bosh_workstation_cpi/network_option"

module BoshWorkstationCpi
  class NetworkOptionCollection
    def self.from_hash(hash)
      new(hash.map do |name, properties|
        NetworkOption.new.tap do |no|
          no.name  = name
          no.ip    = properties["ip"]
          no.netmask = properties["netmask"]
          no.gateway = properties["gateway"]
          no.dns   = properties["dns"]
          no.cloud = properties["cloud_properties"]
        end
      end)
    end

    def initialize(network_options)
      @network_options = network_options
    end

    include Enumerable
    def each(*args, &blk)
      @network_options.each(*args, &blk)
    end

    def add_macs(cloud_name_to_mac)
      each do |network_option|
        raise "Missing mac address for '#{network_option.name}'" \
          unless mac = cloud_name_to_mac[network_option.cloud_name]
        network_option.mac = mac
      end
    end
  end
end
