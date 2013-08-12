# `deployer/instance_manager/workstation.rb` (this file) 
# is loaded by BOSH when it's trying to use workstation plugin.
module Bosh::Deployer
  class InstanceManager
    class Workstation < InstanceManager
      def remote_tunnel(port)
        # noop
      end

      def update_spec(spec)
        properties = spec.properties

        properties["vcenter"] =
          Config.spec_properties["vcenter"] ||
          Config.cloud_options["properties"]["vcenters"].first.dup

        properties["vcenter"]["address"] ||= properties["vcenter"]["host"]
      end
    end

    def persistent_disk_changed?
      false
    end

    def check_dependencies
      if Bosh::Common.which(%w[genisoimage mkisofs]).nil?
        err("either of 'genisoimage' or 'mkisofs' commands must be present")
      end
    end
  end
end
