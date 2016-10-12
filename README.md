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

## Supported operations

* `vagrant destroy`
* `vagrant halt`
* `vagrant provision`
* `vagrant ssh`
* `vagrant status`
* `vagrant up`

## Use ceph as backing strategy

Vagrant-g5k will look into `~/.ceph/config` on each frontend where VMs are started.
You can read[1] for further information on how to configure ceph on grid'5000.

[1] : https://www.grid5000.fr/mediawiki/index.php/Ceph

