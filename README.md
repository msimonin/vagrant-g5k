> The plugin is updated often, this may include breaking changes.

# Vagrant G5K Provider
This is a [Vagrant](http://www.vagrantup.com) 1.2+ plugin that adds an [G5K](https://www.grid5000.fr)
provider to Vagrant, allowing Vagrant to control and provision **virtual machines** on Grid5000.

More generally any *OAR behind ssh* that support launching `kvm` could be used (e.g [Igrida](http://igrida.gforge.inria.fr/)). Thus *vagrant-oar* could be a more appropriate name.

> This plugin requires
  * Vagrant 1.2+,


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

## Note on disk format and backing strategy

Virtual Machines can be booted either :

* From a `qcow2` image stored in the frontend filesystem
* From a rbd image stored in one of the ceph cluster of Grid'5000.

Once the base image is chosen, you can pick one of the following strategy
to back the disk image of the virtual machines :

* `copy`: will make a full copy of the image in your home directory (resp. in the same pool as the rbd)
* `cow`: will create a Copy On write image in your home directory (resp. in the same pool as the rbd)
* `direct`: will use the image directly (you'll need r/w access to the image)
* `snapshot`: will let `kvm` create an ephemeral copy on write image.

## Note on network configuration

Two networking modes are supported :

* NAT networking. VMs traffic is NATed to the outside world.
The outside world can access the VMs on dedicated ports that are mapped in the host of Grid'5000.
```
config.vm.provider "g5k" do |g5k|
  [...]
  g5k.net = {
    "type": "nat",
    "ports": ["2222-:22", "8080-":80]
  }
end
```

e.g : Assuming `parapluie-1.rennes.grid5000.fr` hosts the VM. A SSH tunnel from your local machine to `parapluie-1.rennes.grid5000.fr:8080` will be forwarded to the port `80` of the VM.

* Bridge networking. VMs are given an IP from a Grid'5000 subnet. They can thus communicate with each others using their IPs.

```
config.vm.provider "g5k" do |g5k|
  [...]
  g5k.net = {
    "type": "bridge"
  }
end
```

> Due to the dynamic nature of the subnet reserved on Grid'5000, IPs of the VMs will change accross reboots


## Supported operations

* `vagrant destroy`
* `vagrant halt`
* `vagrant provision`
* `vagrant ssh`
* `vagrant ssh-config`
* `vagrant status`
* `vagrant up`

## Use ceph as backing strategy

Vagrant-g5k will look into `~/.ceph/config` on each frontend where VMs are started.
You can read[1] for further information on how to configure ceph on grid'5000.

[1] : https://www.grid5000.fr/mediawiki/index.php/Ceph

## Developping

* clone the repository
* use `$ bundle` to install all the dependencies (this may take some time)
* then test your code against the provided (or modified) Vagrantfile using :
```
VAGRANT_LOG=debug VAGRANT_DEFAULT_PROVIDER=g5k bundle exec vagrant up
```
