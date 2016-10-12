# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Testing purpose only
#Vagrant.require_plugin "vagrant-g5k"

SITES=['rennes']

Vagrant.configure(2) do |config|
    SITES.each do |site|
      config.vm.define "vm-#{site}" do |my|
        my.vm.box = "dummy"

        my.ssh.username = "root"
        my.ssh.password = ""

        my.vm.provider "g5k" do |g5k|
          g5k.project_id = "vagrant-g5k"
          g5k.site = "#{site}"
          g5k.gateway = "access.grid5000.fr" 
#          g5k.image = {
#             "pool"     => "msimonin_rbds",
#             "rbd"      => "bases/alpine_docker",
#             "snapshot" => "parent",
#             "id"       => "$USER",
#            "conf"      => "$HOME/.ceph/config",
#            "backing"   => "snapshot"
#           }
          g5k.image = {
            "path"    => "/grid5000/virt-images/alpine_docker.qcow2",
            "backing" => "snapshot"
          }
          g5k.ports = ['2222-:22']
          g5k.oar = "virtual != 'none'"
        end #g5k
      end #vm
    end # each

end


