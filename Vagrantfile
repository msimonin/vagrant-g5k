# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Testing purpose only
#Vagrant.require_plugin "vagrant-g5k"

Vagrant.configure(2) do |config|
    config.vm.define "vm1" do |my|
      my.vm.box = "dummy"

      my.ssh.username = "root"
      my.ssh.password = ""

      my.vm.provider "g5k" do |g5k|
        # project id must be unique accross all
        # your projects using vagrant-g5k to avoid conflict 
        # on vm disks
        g5k.project_id = "vagrant-g5k"
        g5k.site = "rennes"
        g5k.username = ENV["USER"]
        g5k.gateway = "access.grid5000.fr"
        g5k.walltime = "01:00:00"

        # Image backed by the ceph cluster
#          g5k.image = {
#             "pool"     => "msimonin_rbds",
#             "rbd"      => "bases/alpine_docker",
#             "snapshot" => "parent",
#             "id"       => "$USER",
#            "conf"      => "$HOME/.ceph/config",
#            "backing"   => "snapshot"
#           }
#
        # Image backed on the frontend filesystem           
        g5k.image = {
          "path"    => "/grid5000/virt-images/alpine_docker.qcow2",
          "backing" => "snapshot"
        }

        # port to expose on the g5k host
        # exposing 22 is mandatory for vagrant-ssh to work
        g5k.ports = ['2222-:22']

        # oar selection of resource
        g5k.oar = "virtual != 'none'"
      end #g5k
    end #vm
    
    # Repeat block to define another vm 
    # config.vm.define "vm2" do |my|
    #   
    # end

end


