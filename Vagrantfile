# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Sample Vagrantfile
#
Vagrant.configure(2) do |config|

    config.vm.provider "g5k" do |g5k, override|
      # This is mandatory for the shared folders to work correctly
      override.nfs.functional = false
      # project id must be unique accross all
      # your projects using vagrant-g5k to avoid conflict
      # on vm disks
      g5k.project_id = "test-vagrant-g5k"

      #g5k.site = "igrida"
      g5k.site = "rennes"
      g5k.username = "msimonin"
       g5k.gateway = "access.grid5000.fr"
      g5k.walltime = "00:10:00"

      # Image backed on the frontend filesystem
      g5k.image = {
      #  :path    => "/udd/msimonin/precise.qcow2",
        :path    => "/home/msimonin/public/ubuntu1404-9p.qcow2",
        :backing => "snapshot"
      }

      ## Bridged network : this allow VMs to communicate
      #g5k.net = {
      #  :type => "bridge"
      #}

      ## Nat network : VMs will only have access to the external world
      ## Forwarding ports will allow you to access services hosted inside the
      ## VM.
      g5k.net = {
        :type => "nat",
        :ports => ["2222-:22"]
      }

      ## OAR selection of resource
      g5k.oar = "virtual != 'none'"
      #g5k.oar = "virtual != 'None' and network_address in ('paranoia-2.rennes.grid5000.fr')"
      #g5k.oar = "network_address in ('igrida12-12.irisa.fr')"

      ## VM size customization default values are
      ## cpu => -1 -> all the cpu of the reserved node
      ## mem => -1 -> all the mem of the reserved node
      ##
      g5k.resources = {
        :cpu => 1,
        :mem => 2048
      }
    end #g5k

    ## This define a VM.
    ## a g5k provider section will override top level options
    ## To define multiple VMs you can
    ## * either repeat the block
    ## * loop over using (1..N).each block
    config.vm.define "exp5" do |my|
      my.vm.box = "dummy"
      ## Configure the shared folders between your host and the VM
      my.vm.synced_folder ".", "/vagrant", type: "rsync", disabled: false
      ## This is mandatory until #6 is fixed
      ## In particular this is needed for the shared folders
      my.ssh.insert_key = false

    end #vm

end
