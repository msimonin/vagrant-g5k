> The plugin is updated frequently, this may include breaking changes.

# Vagrant G5K Provider
This is a [Vagrant](http://www.vagrantup.com) 1.2+ plugin that adds an
[G5K](https://www.grid5000.fr) provider to Vagrant, allowing Vagrant to control
and provision **virtual machines** on Grid5000.

More generally any *OAR behind ssh* that support launching `kvm` could be used
(e.g [Igrida](http://igrida.gforge.inria.fr/)). Thus *vagrant-oar* could be a
more appropriate name.

> This plugin requires
  * Vagrant 1.2+,

---

* [Supported operations](#supported-operations)
* [Usage](#usage)
* [Configuration](#configuration)
* [Note on the insecure vagrant key](#note-on-the-insecure-vagrant-key)
* [Note on shared folders](note-on-local-shared-folders)
  * [Local files](#local-files)
  * [Grid5000 home](#grid5000-home)
* [Note on disk format and backing strategy](#note-on-disk-format-and-backing-strategy)
* [Note on network configuration](#note-on-network-configuration)
  * [NAT networking](#nat-networking)
  * [Bridge networking](#bridge-networking)
* [Note on resource demand](#note-on-resource-demand)
* [Reservation in advance](#reservation-in-advance)
* [Developping](#developping)

---

## Supported operations

* `vagrant destroy`
* `vagrant halt`
* `vagrant provision`
* `vagrant rsync|rsync-auto`
* `vagrant ssh`
* `vagrant ssh-config`
* `vagrant status`
* `vagrant up`


## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, `vagrant up` and specify the `g5k` provider. An example is
shown below.

```
$ vagrant plugin install vagrant-g5k
$ # (optionnally) get the latest Vagrantfile
$ wget https://raw.githubusercontent.com/msimonin/vagrant-g5k/master/Vagrantfile
$ vagrant up --provider=g5k
...
```
Vagrant requires a box to start with. As a consequence you can add one `dummy`
box with the following command :

```
 vagrant box add dummy https://github.com/msimonin/vagrant-g5k/raw/master/dummy.box
```


## Configuration

Check the Vagrantfile.

## Note on the insecure vagrant key

By default, Vagrant uses a insecure key to connect to the VM.
Prior to some operation vagrant will replace this by a generated key.
This operation isn't supported by vagrant-g5k thus you need to specify
`config.vmssh.insert_key = false` in the Vagrantfile.

For instance this is needed when using shared folders, hostmanager plugin...

## Note on shared folders

### Local files

Rsync shared folders are supported. The copy of your local files is hooked in
the `up` phase. After this you can use :

* `vagrant rsync` to force a synchronization
* `vagrant rsync-auto` to watch your local modifications

### Grid5000 home

Your home on Grid'5000 can be shared with your virtual machine through VirtFS.
If the VM supports Plan 9 folder sharing you can connect to the VM and type :

```
mkdir /g5k
mount -t 9p -o trans=virtio hostshare /g5k -oversion=9p2000.L
```


## Note on disk format and backing strategy

Virtual Machines can be booted either :

* From a `qcow2` image stored in the frontend filesystem : 

```
g5k.image = {
  :path     => # path to the image (absolute or reltive to the user home)
  :strategy => # strategy to use (see below)
}
```

* From a rbd image stored in one of the ceph cluster of Grid'5000.

```
g5k.image = {
  :pool     => # ceph pool to use 
  :rbd      => # rbd in the pool to use
  :conf     => # path to the ceph config file
  :id       => # id to use to contact ceph
  :strategy => # strategy to use (see below)
}
```


Once the base image is chosen, you can pick one of the following strategy
to back the disk image of the virtual machines :

* `copy`: will make a full copy of the image in your home directory (resp. in
  the same pool as the rbd)
* `cow`: will create a Copy On write image in your home directory (resp. in the
  same pool as the rbd)
* `direct`: will use the image directly (you'll need r/w access to the image)
* `snapshot`: will let `kvm` create an ephemeral copy on write image.

### Use ceph as backing strategy

Vagrant-g5k will look into `~/.ceph/config` on each frontend where VMs are started.
You can read[1] for further information on how to configure ceph on grid'5000.

[1] : https://www.grid5000.fr/mediawiki/index.php/Ceph

## Note on network configuration

Two networking modes are supported :

### NAT networking

VMs traffic is NATed to the outside world.  The outside world
  can access the VMs on dedicated ports that are mapped in the host of
  Grid'5000.  

```
config.vm.provider "g5k" do |g5k|
  [...]
  g5k.net = {
    :type  => "nat",
    :ports => ["2222-:22", "8080-":80]
  }
end
```

e.g : Assuming `parapluie-1.rennes.grid5000.fr` hosts the VM. A SSH tunnel from
your local machine to `parapluie-1.rennes.grid5000.fr:8080` will be forwarded to
the port `80` of the VM.

### Bridge networking

VMs are given an IP from a Grid'5000 subnet. They can thus
  communicate with each others using their IPs.

```
config.vm.provider "g5k" do |g5k|
  [...]
  g5k.net = {
    :type => "bridge"
  }
end
```

> Due to the dynamic nature of the subnet reserved on Grid'5000, IPs of the VMs
> will change accross reboots a /18 is reserved but only the first 1024 ips are
> reserved for the VMs. That means you can use the remaining ips without any
> conflict.

## Note on resource demand

CPU and memory demand can be ajusted with the following in your Vagrantfile.

```
config.vm.provider "g5k" do |g5k|
  [...]
  g5k.resource = {
    :cpu => 2,
    :mem => 4096
  }
end
```
You can use `:cpu => -1` to express that you want all the cpu of the reserved
node (but not necesseraly all the memory). Similarly `:mem => -1` will give you
all the memory available on the reserved node. These are the default values.

## Reservation in advance

If you plan to use a reservation or if you expect all your VMs to be ready
almost on the same time you can use a job container (see:
https://www.grid5000.fr/mediawiki/index.php/Advanced_OAR#Container_jobs)

* First create you container job using OAR cli from the frontend of your choice.
* Then instruct vagrant-g5k about this job container id in the Vagrantfile :

```
config.vm.provider "g5k" do |g5k|
  [...]
  g5k.job_container_id = "your container job id"
end
```

## Developping

* clone the repository
* use `$ bundle` to install all the dependencies (this may take some time)
* then test your code against the provided (or modified) Vagrantfile using :
```
VAGRANT_LOG=debug VAGRANT_DEFAULT_PROVIDER=g5k bundle exec vagrant up
```
