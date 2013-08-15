module BoshWorkstationCpi
  class CpiOptions
    attr_reader :host, :user, :password
    attr_reader :agent

    def self.from_vsphere(options, logger)
      vcenter     = options["vcenters"].first
      datacenter  = vcenter["datacenters"].first

      credentials = vcenter.values_at("host", "user", "password")
      store_dir   = datacenter["datastore_pattern"]
      agent       = options["agent"]
      new(*credentials, store_dir, agent, logger)
    end

    def initialize(host, user, password, store_dir, agent, logger)
      @host = host
      @user = user
      @password = password
      @store_dir = store_dir
      @agent = agent
      @logger = logger
    end

    def local_access?
      if ENV["BOSH_WORKSTATION_CPI_REMOTE_ACCESS"]
        @logger.info("cpi_options.#{__method__} remote_access=true")
        false
      else
        File.directory?(@store_dir)
      end
    end

    def stemcells_dir
      "#{@store_dir}/stemcells"
    end

    def vms_dir
      "#{@store_dir}/vms"
    end

    def disks_dir
      "#{@store_dir}/disks"
    end
  end
end
