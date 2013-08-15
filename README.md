### Installation

Install `bosh_cli`, `bosh_cli_plugin_micro`, 
and `bosh_workstations_cpi` as shown below:

```
gem install bosh_cli              -v 1.5.0.pre.883 --source https://s3.amazonaws.com/bosh-ci-pipeline/883/gems
gem install bosh_cli_plugin_micro -v 1.5.0.pre.883 --source https://s3.amazonaws.com/bosh-ci-pipeline/883/gems

# bosh_workstation_cpi is not on rubygems as of now
git clone https://github.com/cppforlife/bosh_workstation_cpi
cd bosh_workstation_cpi
gem build bosh_workstation_cpi.gemspec
gem install bosh_workstation_cpi*.gem
bosh -v
```

Alternatively use bundler with included `Gemfile`
(primarily used when developing this gem) and prefix all 
bosh/bosh_workstation_cpi commands with `bundle exec`:

```
git clone https://github.com/cppforlife/bosh_workstation_cpi
cd bosh_workstation_cpi
bundle
bundle exec bosh -v
```


### Usage

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

- `bosh deployment dev/deployments/nats.yml && bosh deploy` (example single job NATS)
  - Don't forget to change director_uuid

- `bosh deployment dev/deployments/cf.yml && bosh deploy` (example CF)
  - Don't forget to change director_uuid
  - Turn on `dev/local_dns_server.rb`


### Debugging

- `BOSH_WORKSTATION_CPI_GUI` forces VirtualBox provider
  to use GUI when starting up VMs
  (VMs are started in headless mode by default)

- `BOSH_WORKSTATION_CPI_REMOTE_ACCESS` forces CPI
  to always use remote strategy 
  even when local access is possible

- Tail 'dev/deployments/micro/bosh_micro_deploy.log'
  to see detailed logs when doing MicroBOSH deploy

- `bosh task <INT> --debug` to see detailed logs
  when doing any actions on the Director


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


### Thanks

Pieces of `BoshWorkstationCpi::VirtualBox::Driver` class are taken from Vagrant.
