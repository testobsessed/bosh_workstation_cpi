# Welcome to BOSH Workstation CPI

The BOSH Workstation CPI allows you to do a BOSH deploy onto VirtualBox.
This means you can create a BOSH release and test it, all on your local machine.

## Installing

### 1. Install and Configure Virtual Box

To use the BOSH workstation CPI you will need [VirtualBox version 4.2.16](https://www.virtualbox.org/wiki/Downloads) installed.

You need to set up a host-only VirtualBox network:
  # Open VirtualBox
  # Choose VirtualBox > Preferences > Network
  # Create new network with DHCP disabled named `vboxnet0` (the default). Currently only this name works.

### 2. Install BOSH Gems

Install `bosh_cli` and `bosh_cli_plugin_micro`

```
$ gem install bosh_cli              -v 1.5.0.pre.883 --source https://s3.amazonaws.com/bosh-ci-pipeline/883/gems
$ gem install bosh_cli_plugin_micro -v 1.5.0.pre.883 --source https://s3.amazonaws.com/bosh-ci-pipeline/883/gems
```
Make sure you have the right version of bosh with `bosh -v`.

### 3. Build the bosh_workstation_cpi Gem

Currently the bosh_workstation_cpi is not on rubygems. You need to build and install it.
Clone this repository and cd into the directory. Then:

```
$ gem build bosh_workstation_cpi.gemspec
$ gem install bosh_workstation_cpi*.gem
```

### 4. Download the Stemcells

You need a micro bosh stemcell.
The stemcell required to make BOSH Workstation CPI work is not yet in the public BOSH blobstore.
You can get it from the development build artifacts repository at https://s3.amazonaws.com/bosh-ci-pipeline/

```
$ curl https://s3.amazonaws.com/bosh-ci-pipeline/896/micro-bosh-stemcell/vsphere/micro-bosh-stemcell-latest-vsphere-esxi-ubuntu.tgz -o micro-bosh-stemcell-latest-vsphere-esxi-ubuntu.tgz

```

Note that because the s3 bucket is just a repository for build artifacts, the path may change.

### 5. Set Up Your MicroBOSH

Prepare the MicroBOSH deployer plugin to work with workstation.

```
$ bosh_workstation_cpi_set_up
```

CD into the deployments directory. This directory includes example MicroBOSH and BOSH manifest

```
$ cd dev/deployments
```

Edit `micro/micro_bosh.yml` to add the username and password for your machine.

```
$ bosh micro deployment micro/
```

Create the micro bosh with the stemcell you downloaded. This creates new VM in VirtualBox.

```
$ bosh micro deploy _path_/micro-bosh-stemcell-latest-vsphere-esxi-ubuntu.tgz
```

Target your new microbosh and log in:

```
$ bosh target 192.168.56.2:25555
$ bosh login
Your username: admin
Enter password: admin
```

Configure your micro bosh to use the BOSH Workstation CPI:

```
$ bosh_workstation_cpi_inject 192.168.56.2 vcap c1oudc0w
$ bosh_workstation_cpi_switch 192.168.56.2 vcap c1oudc0w
```

Wait about 30 seconds, then make sure that your microbosh is configured correctly:

```
$ bosh status

Director
  Name       bosh_micro01
  URL        https://192.168.56.2:25555
  Version    1.5.0.pre.896 (release:f694e3d2 bosh:f694e3d2)
  User       admin
  UUID       39be73f2-103a-4968-9645-9cd6406aedce
  CPI        workstation
  dns        enabled (domain_name: microbosh)
```

### 6. Run the Local DNS Server

```
$ sudo ruby dev/local_dns_server.rb
```

You are now ready to use your micro bosh to do a deployment on your local machine.
The next section covers how to install Cloud Foundry, but you could install any BOSH release.

## Installing Cloud Foundry

### 1. Upload Your Stemcell

You will need a stemcell for your deployment
The stemcells required to make BOSH Workstation CPI work are not yet in the public BOSH blobstore.
You can get them from the development build artifacts repository at https://s3.amazonaws.com/bosh-ci-pipeline/

```
$ curl https://s3.amazonaws.com/bosh-ci-pipeline/897/bosh-stemcell/aws/bosh-stemcell-897-aws-xen-ubuntu.tgz -o bosh-stemcell-897-aws-xen-ubuntu.tgz
```
Once you have your stemcell you can upload it to your microbosh with the command:

```
bosh upload stemcell _path_/bosh-stemcell-vsphere-750-5db4fe.tgz`
```

The stemcell is referenced in the two sample manifests, nats.yml and cf.yml. Be sure to change the
stemcell name in these files to match your stemcell name.

### 2. Upload Your Release

- `bosh upload release ~/workspace/releases/cf-133.1-dev.tgz`
  - Referenced from `nats.yml` manifest
  - If `bosh releases` does not show your release after uploading
    wait for all `bosh tasks` to finish

### 3. Update Your Manifest

- `bosh deployment dev/deployments/nats.yml && bosh deploy` (example single job NATS)
  - Don't forget to change director_uuid

- `bosh deployment dev/deployments/cf.yml && bosh deploy` (example CF)
  - Don't forget to change director_uuid
  - Turn on `dev/local_dns_server.rb`


## Debugging

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
