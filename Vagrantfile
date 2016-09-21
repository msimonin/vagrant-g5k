# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Testing purpose only
Vagrant.require_plugin "vagrant-g5k"

Vagrant.configure(2) do |config|
    # box isn't used
    config.vm.define "vm" do |my|
      my.vm.box = "dummy"
      my.vm.provision "ansible", :playbook => "playbook.yml"
    end

    # user to log with inside the vm
    config.ssh.username = "root"
    # password to use to log inside the vm 
    config.ssh.password = ""
    
    config.vm.provider "g5k" do |g5k|
      # The project id. 
      # It is used to generate uniq remote storage for images
      # It must be uniq accros all project managed by vagrant.
      g5k.project_id = "vagrant-g5k"

      # user name used to connect to g5k
      # default to ENV["USER"]
      # g5k.username = "john"

      # private key 
      # g5k.private_key = File.join(ENV['HOME'], ".ssh/id_rsa_discovery")

      # site to use
      g5k.site = "nantes"

      # walltime to use
      # g5k.walltime = "02:00:00" 

      # image location 
      g5k.image = {
        "path" => "/home/msimonin/public/alpine_docker_analyse_090916.qcow2",
        "backing" => "snapshot"
      }

      # it could be backed by the ceph
      # g5k.image = { 
      #   "pool"     => "msimonin_rbds",
      #   "rbd"      => "bases/alpine_docker",
      #   "snapshot" => "parent",
      #   "id"       => "$USER",
      #   "conf"     => "$HOME/.ceph/config",
      #   "backing"  => "cow"
      # }

      # ports to expose (at least ssh has to be forwarded)
      g5k.ports = ['2222-:22']
    end


     
end


