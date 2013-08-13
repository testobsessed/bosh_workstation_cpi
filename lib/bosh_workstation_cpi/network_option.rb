module BoshWorkstationCpi
  class NetworkOption
    attr_accessor :name
    attr_accessor :ip, :netmask, :gateway, :dns
    attr_accessor :mac
    attr_accessor :cloud

    def formatted_mac
      mac.downcase.scan(/../).join(":")
    end

    def cloud_name
      cloud["name"]
    end
  end
end
