# Vagrant G5K Provider
This is a [Vagrant](http://www.vagrantup.com) 1.2+ plugin that adds an [G5K](https://www.grid5000.fr)
provider to Vagrant, allowing Vagrant to control and provision machines in
Grid5000.

**NOTE:** This plugin requires Vagrant 1.2+,

## Features

* Boot one vm instance
* SSH into the instances.

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, `vagrant up` and specify the `g5k` provider. An example is
shown below.

```
$ vagrant plugin install vagrant-g5k
...
$ vagrant up --provider=g5k
...
```
## Configuration

As an example we give this Vagrantfile:



```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :
#

Vagrant.configure(2) do |config|
    # box isn't used
    config.vm.box = "public/alpine_docker"
    # user to log with inside the vm
    config.ssh.username = "root"
    # password to use to log inside the vm
    config.ssh.password = ""

    config.vm.provider "g5k" do |g5k|
      g5k.username = "msimonin"
      g5k.site = "lille"
      g5k.image_location = "/home/msimonin/public/alpine_docker.qcow2"
      g5k.image_type = "local"
      g5k.image_strategy = "snapshot"
    end

end
```
