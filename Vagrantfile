# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Testing purpose only
Vagrant.require_plugin "vagrant-g5k"

Vagrant.configure(2) do |config|
    # box isn't used
    config.vm.define "vm" do |my|
      my.vm.box = "dummy"
    end

    # user to log with inside the vm
    # config.ssh.username = "root"
    # password to use to log inside the vm 
    # config.ssh.password = ""

    config.vm.provider "g5k" do |g5k|
      # user name used to connect to g5k
      g5k.username = ENV['USER']

      # private key 
      # g5k.private_key = File.join(ENV['HOME'], ".ssh/id_rsa_discovery")

      # site to use
      g5k.site = "rennes"

      # walltime to use
      # g5k.walltime = "02:00:00" 

      # image location 
      #g5k.image = {
      #  "path" => "/grid5000/virt-images/alpine_docker.qcow2",
      #  "backing" => "cow"
      #}

      # it could be backed by the ceph
      g5k.image = { 
        "pool"     => "msimonin_rbds",
        "rbd"      => "bases/boxcutter_ubuntu1404",
        "snapshot" => "parent",
        "id"       => "$USER",
        "conf"     => "$HOME/.ceph/config",
        "backing"  => "cow"
      }
      
      # g5k.backing_strategy = "snapshot"
      #   this is a copy on write strategy 
      #   image_location is use to read, an epehemeral disk will hold the writes
      # if not specified this means that the image is used in r/w mode.
      #   changes will be persistent
      g5k.backing_strategy = "cow"
      # ports to expose (at least ssh has to be forwarded)
      g5k.ports = ['2222-:22','3000-:3000']
    end


     
end


