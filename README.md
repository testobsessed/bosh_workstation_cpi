### Installing BOSH CLI gems

#### gem install

- `gem install bosh_cli              -v 1.5.0.pre.883 --source https://s3.amazonaws.com/bosh-ci-pipeline/883/gems`
- `gem install bosh_cli_plugin_micro -v 1.5.0.pre.883 --source https://s3.amazonaws.com/bosh-ci-pipeline/883/gems`

#### via Gemfile

- Add `gem :bosh_workstation_cpi, git: "https://github.com/cppforlife/bosh_workstation_cpi"`
  to your Gemfile and then bundle


### Using Workstation CPI

Note: Depending on how you installed BOSH CLI gems
you might have to `bundle exec` commands below.

- Set up host-only VirtualBox network
  - Open VirtualBox
  - VirtualBox > Preferences > Network
  - Create new network with DHCP disabled
    - Currently only `vboxnet0` works

- `bosh_workstation_cpi_set_up`
  - Prepares MicroBOSH deployer plugin to work with workstation

- `cd ${SOURCE}/dev/deployments`
  - This directory includes example MicroBOSH and BOSH manifest

- `bosh micro deployment micro/`
  - Update `micro/micro_bosh.yml` with your network/virtualbox configuration
  - Keep fake vpshere configuration

- `bosh micro deploy ~/workspace/stemcells/micro-bosh-stemcell-vsphere-749-e74f85.tgz`
  - This creates new VM in VirtualBox
  - Use latest vsphere stemcell

- `bosh target 192.168.56.2:25555`
  - Credentials: admin/admin

- `bosh_workstation_cpi_inject 192.168.56.2 vcap c1oudc0w`
  - Uploads then installs this gem for MicroBOSH director
  - This is what provides Workstation CPI on MicroBOSH

- `bosh_workstation_cpi_switch 192.168.56.2 vcap c1oudc0w`
  - Switches MicroBOSH director to use Workstation CPI

- `bosh status`
  - Make sure that CPI is `workstation`
  - It takes about 30sec or so to restart all components in MicroBOSH

- `bosh upload stemcell ~/workspace/stemcells/bosh-stemcell-vsphere-750-5db4fe.tgz`
  - Referenced from `nats.yml` manifest

- `bosh upload release ~/workspace/releases/cf-133.1-dev.tgz`
  - Referenced from `nats.yml` manifest
  - If `bosh releases` does not show your release after uploading
    wait for all `bosh tasks` to finish

- `bosh deployment dev/deployments/nats.yml`
  - Don't forget to change director_uuid

- `bosh deploy`


### Debugging Options

- `BOSH_WORKSTATION_CPI_GUI` forces VirtualBox provider
  to use GUI when starting up VMs
  (VMs are started in headless mode by default)

- `BOSH_WORKSTATION_CPI_REMOTE_ACCESS` forces CPI
  to always use remote strategy 
  even when local access is possible


### BOSH Integration

- `deployer/instance_manager/workstation.rb` 
  is an extension to `bosh_cli_plugin_micro` to use Workstation CPI

- `lib/cloud/workstation.rb` 
  is an extension to `director` to use Workstation CPI


### Problems

- deployer plugin needs to use empty default config
  if plugin specific file is not found in 
  `bosh_cli_plugin_micro/config`

- wait for agent to come up for longer time
  (`instance_manager.rb` - wait_until_agent_ready)

- wait for vm to start and run through
  all bosh_agent bootstrap steps
  (currently sleeps in `attach_disk.rb` when powering on)

- sleep for a bit for showvminfo to become available
  (in `DiskAttacher#read_empty_scsi_ports_and_devices`)

- `InstanceManager#update_spec` fakes out vsphere configuration


### Misc

- Run irb with access to Director gems:
  `sudo GEM_HOME=/var/vcap/packages/director/gem_home /var/vcap/packages/ruby/bin/irb`
