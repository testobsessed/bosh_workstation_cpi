# Welcome to BOSH Workstation CPI

The BOSH Workstation CPI allows you to do a BOSH deploy onto VirtualBox.
This means you can create a BOSH release and test it, all on your local machine.

## Prerequisites

### 1. Install and Configure Virtual Box

BOSH workstation CPI runs on Virtual Box.

Before you install Virtual Box, you will need `mkisofs`. Check that you have it:

```
$ which mkisofs
```

If you don't have `mkisofs`, install `cdrtools` using your favorite package manager.
For example, on MacOS:

```
$ brew install cdrtools
```

If you encounter difficulty installing cdrtools on MacOS, you may need the Xcode command line tools installed.

Next, install [VirtualBox](https://www.virtualbox.org/wiki/Downloads), minimum version 4.2.16.

### 2. Set Up the Network

Set up a host-only VirtualBox network:
1. Open VirtualBox
1. Choose VirtualBox > Preferences > Network
1. Create new network with DHCP disabled named `vboxnet0` (the default). Currently only this name works.

Check that the vboxnet0 network is configured:

```
$ ifconfig

_...other entries..._
vboxnet0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 0a:00:27:00:00:00
	inet 192.168.56.1 netmask 0xffffff00 broadcast 192.168.56.255

```

Finally, make sure you can ping the IP address 192.168.56.1.

### 3. Install BOSH Gems

You need both the `bosh_cli` and `bosh_cli_plugin_micro` gems.
These instructions rely on a cersion 1.5.0.pre.908 or later of these gems.
Because this version of these gems have not yet been released,
you need to specify the version and gem source when installing. For example:

```
$ gem install bosh_cli              -v 1.5.0.pre.908 --source https://s3.amazonaws.com/bosh-ci-pipeline/908/gems
$ gem install bosh_cli_plugin_micro -v 1.5.0.pre.908 --source https://s3.amazonaws.com/bosh-ci-pipeline/908/gems
```
Make sure you have the right version of bosh by running `bosh -v`.

```
$ bosh -v
BOSH 1.5.0.pre.908
```

## Installation and Configuration

### 1. Build the bosh_workstation_cpi Gem

Currently the bosh_workstation_cpi is not on rubygems. You need to build and install it.
Clone this repository and cd into the directory. Then:

```
$ gem build bosh_workstation_cpi.gemspec
$ gem install bosh_workstation_cpi*.gem
```

### 2. Download the Stemcells

You need a micro bosh stemcell.
The stemcell required to make BOSH Workstation CPI work is not yet in the public BOSH blobstore.
You can get it from the development build artifacts repository at https://s3.amazonaws.com/bosh-ci-pipeline/

```
$ curl https://s3.amazonaws.com/bosh-ci-pipeline/896/micro-bosh-stemcell/vsphere/micro-bosh-stemcell-latest-vsphere-esxi-ubuntu.tgz -o micro-bosh-stemcell-latest-vsphere-esxi-ubuntu.tgz

```

Note that because the s3 bucket is just a repository for build artifacts, the path may change.

### 3. Set Up Your MicroBOSH

Prepare the MicroBOSH deployer plugin to work with workstation.

```
$ bosh_workstation_cpi_set_up
```

CD into the deployments directory. This directory includes example MicroBOSH and BOSH manifest

```
$ cd dev/deployments
```

Edit `micro/micro_bosh.yml` to add the username and password for your machine in the `vcenters` section.
Then point bosh to the micro deployment file:

```
$ bosh micro deployment micro/
```

Create the micro bosh with the stemcell you downloaded. This creates new VM in VirtualBox:

```
$ bosh micro deploy _path_/micro-bosh-stemcell-latest-vsphere-esxi-ubuntu.tgz
```

### 4. Configure MicroBOSH

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

Wait about 30 seconds, then make sure that your microbosh is configured correctly.
When you run `bosh status` you should see that the CPI is set to workstation:

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

### 5. Run the Local DNS Server

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
$ curl https://s3.amazonaws.com/bosh-ci-pipeline/908/bosh-stemcell/vsphere/bosh-stemcell-908-vsphere-esxi-ubuntu.tgz -o bosh-stemcell-908-vsphere-esxi-ubuntu.tgz
```
Once you have your stemcell you can upload it to your microbosh with the command:

```
bosh upload stemcell _path_/bosh-stemcell-908-vsphere-esxi-ubuntu.tgz
```

The stemcell is referenced in the two sample manifests in the `dev/deployments directory`, nats.yml and cf.yml.
Be sure to change the
stemcell name in these files to match your stemcell name.

### 2. Upload Your Release

You can use a final release from the `cf-release` repo, or create your own release.
To use an existing final release:

```
$ git clone https://github.com/cloudfoundry/cf-release
$ git checkout deployed-to-prod
$ bosh upload release releases/cf-137.yml
```
Verify that the release got uploaded with `bosh releases`:

```
$ bosh releases

+------+----------+-------------+
| Name | Versions | Commit Hash |
+------+----------+-------------+
| cf   | 137      | d35ed835+   |
+------+----------+-------------+
(+) Uncommitted changes

```

If `bosh releases` does not show your release after uploading
wait for all `bosh tasks` to finish.

### 3. Update Your Manifest

There are two sample manifests included in this repo, both
under the `dev/deployments` directory: `cf.yml` and `nats.yml`.
You need to edit the manifest as follows.

First, change the director_uuid in your to match your director.
Use `bosh status` to get the UUID setting for your director.
Then edit your manifest to change the director_uuid setting.

Next make sure that the release name referenced in your manifest matches
the release name you uploaded to your director.
So, for example, if `bosh releases`
shows the release name as `cf`, make sure your cf.yml shows:

```
releases:
- name: cf
  version: latest
```

### 4. Deploy the Release

You need to set the deployment with the `bosh deployment` command:

```
$ bosh deployment dev/deployments/cf.yml
```

Then deploy:

```
$ bosh deploy
```


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

If you do not have the machine username and password configured correctly, you will may see an operation timed out error.

If you specify a folder that you cannot write to in the micro_bosh.yml file, you'll see a mysterious fail.

### Thanks

Pieces of `BoshWorkstationCpi::VirtualBox::Driver` class are taken from Vagrant.
