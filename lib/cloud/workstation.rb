# `cloud/workstation.rb` (this file) is loaded by BOSH
# when it's trying to use workstation plugin.
require "bosh_workstation_cpi"
require "bosh_workstation_cpi/cpi"
Bosh::Clouds::Workstation = BoshWorkstationCpi::Cpi
