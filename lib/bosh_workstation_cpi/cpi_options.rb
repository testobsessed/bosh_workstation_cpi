module BoshWorkstationCpi
  class CpiOptions
    attr_reader :host, :user, :password
    attr_reader :agent

    def self.from_vsphere(options)
      vcenter     = options["vcenters"].first
      datacenter  = vcenter["datacenters"].first

      credentials = vcenter.values_at("host", "user", "password")
      store_dir   = datacenter["datastore_pattern"]
      agent       = options["agent"]
      new(*credentials, store_dir, agent)
    end

    def initialize(host, user, password, store_dir, agent)
      @host = host
      @user = user
      @password = password
      @store_dir = store_dir
      @agent = agent
    end

    def local_access?
      return false if ENV["BOSH_VAGRANT_CPI_REMOTE_ACCESS"]
      File.directory?(@store_dir)
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
