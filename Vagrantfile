# -*- mode: ruby -*-
# vi: set ft=ruby :
#

# Testing purpose only
Vagrant.require_plugin "vagrant-g5k"

Vagrant.configure(2) do |config|
    # box isn't used
    (1..3).each do |i|
      config.vm.define "vm_#{i}" do |my|
        my.vm.box = "dummy"
      end
    end

    # user to log with inside the vm
    config.ssh.username = "root"
    # password to use to log inside the vm 
    config.ssh.password = ""

    config.vm.provider "g5k" do |g5k|
      # user name used to connect to g5k
      g5k.username = "msimonin"
      # site to use
      g5k.site = "rennes"
      # image location 
      g5k.image_location = "/grid5000/virt-images/alpine_docker.qcow2"
      # it could be backed by the ceph
      # g5k.image_location = "rbd:msimonin_rbds/virt/alpine_docker_analyse-090916:id=msimonin:conf=/home/msimonin/.ceph/config"
      g5k.backing_strategy = "snapshot"
      # ports to expose (at least ssh has to be forwarded)
      g5k.ports = ['2222-:22']
    end


     
end


