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

Check the Vagrantfile.

## Supported operations

* `vagrant up`
* `vagrant ssh`
* `vagrant destroy`
