# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Testing purpose only
#Vagrant.require_plugin "vagrant-g5k"
NB_G5K=1
NB_IGRIDA=1

Vagrant.configure(2) do |config|
    (0..NB_G5K-1).each do |i|
      config.vm.define "vm-g5k-#{i}" do |my|
        my.vm.box = "dummy"

        my.ssh.username = "root"
        my.ssh.password = ""

        my.vm.provider "g5k" do |g5k|
          g5k.project_id = "vagrant-g5k"
          g5k.site = "nancy"
          g5k.gateway = "access.grid5000.fr" 
          g5k.image = { 
             "pool"     => "msimonin_rbds",
             "rbd"      => "bases/alpine_docker",
             "snapshot" => "parent",
             "id"       => "$USER",
             "conf"     => "$HOME/.ceph/config",
             "backing"  => "snapshot"
           }
          g5k.ports = ['2222-:22']
        end #g5k
      end #vm
    end # each


    (0..NB_IGRIDA-1).each do |i|
      config.vm.define "vm-igrida-#{i}" do |my|
        my.vm.box = "dummy"

        my.vm.provider "g5k" do |g5k|
          g5k.project_id = "vagrant-g5k"
          g5k.site = "igrida-oar-frontend"
          g5k.gateway = "transit.irisa.fr" 
          g5k.image = { 
            "path" => "/udd/msimonin/precise.qcow2",
            "backing" => "snapshot"
           }
          g5k.ports = ['2222-:22']
        end #g5k
      end # vm
    end # each

end


