# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Sample Vagrantfile
#
Vagrant.configure(2) do |config|

    config.vm.provider "g5k" do |g5k|
      # project id must be unique accross all
      # your projects using vagrant-g5k to avoid conflict 
      # on vm disks
      g5k.project_id = "vagrant-g5k"
      g5k.site = "rennes"
      g5k.username = ENV["USER"]
      g5k.gateway = "access.grid5000.fr"
      g5k.walltime = "01:00:00"

      ## Image backed by the ceph cluster
      #g5k.image = {
      #   :pool      => "msimonin_rbds",
      #   :rbd       => "bases/ubuntu1404-9p",
      #   :snapshot  => "parent",
      #   :id        => "$USER",
      #   :conf      => "$HOME/.ceph/config",
      #   :backing   => "copy"
      #}

      # Image backed on the frontend filesystem           
      g5k.image = {
        :path    => "/grid5000/virt-images/alpine_docker.qcow2",
        :backing => "copy"
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

      ## VM size customization default values are
      ## cpu => -1 -> all the cpu of the reserved node
      ## mem => -1 -> all the mem of the reserved node
      ## 
      #g5k.resources = {
      #  :cpu => 1,
      #  :mem => 2048
      #}
    end #g5k

    ## This define a VM.
    ## a g5k provider section will override top level options
    ## To define multiple VMs you can 
    ## * either repeat the block
    ## * loop over using (1..N).each block
    config.vm.define "vm" do |my|
      my.vm.box = "dummy"
      
      ## Access to the vm
      ## This is specific to alpine_docker
      ## It's better to use a vagrant image
      ## converted to qcow2
      my.ssh.username = "root"
      my.ssh.password = ""

    end #vm

end


