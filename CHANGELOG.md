# 0.9.7

  * Fix vagrant 1.9.5 compatibility. Note that it breaks compatibility with older version of
   vagrant
    [[-]](https://github.com/msimonin/vagrant-g5k/commit/29f823c2460e03d5d93e6b2077d1af1b0d17e63b)

# 0.9.6

  * Fix Multiple nodes may be reserved for a single vm 
  [[-]](https://github.com/msimonin/vagrant-g5k/commit/c90d61ed7cdcf90dd5c903736c5153168e35a1f0)

# 0.9.5

  * Fix import error on command 
  [[-]](https://github.com/msimonin/vagrant-g5k/commit/d5b69cc48c2e38de0895498c7bf1dfe7df2fa96c)
  * bridge mode now reserves a /18 and take ips in the first 1024 ips. 
  [[-]](https://github.com/msimonin/vagrant-g5k/commit/9d7511e030cae63c6496c7c96fb713c6347dbadd)
  * Support for container job
  [[-]](https://github.com/msimonin/vagrant-g5k/commit/cf30db9324a2a5dc29b96f43372786b4c7843e53)
  * Document sharing g5k user home

# 0.9.4

  * fix version mistake 

# 0.9.3 

  * Rsync support. The Vagrantfile needs to be updated.

# 0.9.2

  * Make the monitor socket location unique

# 0.9.1

  * Allow custom cpu and memory demands.

# 0.9.0

  * Code refactoring :
    * Introduce oar_driver to handle operation involving oar
    * Introduce net_driver to configure the network used by the VMs
    * Introduce disk_driver to configure the disk used by the VMs

# 0.0.18

  * Fix update_subnet_use when using nat network

# 0.0.17

  * Add bridged network support
  * Add support for ssh run command (cli : vagrant ssh vm -c "...".)
  * Add generic lockable function
  * Add generic GetState Middleware (destroy can be called even if the VM is
  terminated)

# 0.0.16

  * Improve stdout (add information on physical node)
  * Stop the polling if the job is terminated

# 0.0.15

  * Allow parallel boot

# 0.0.14

  * Add custom oar properties
  * Display the name of the node

# 0.0.13

  * Let vagrant configure the private_key to use to connect to the VM

# 0.0.12

  * Send checkpoint signal to the VM when deleting the job

# 0.0.11

  * Support for other "OAR behind ssh scheduler" (e.g Igrida)
  * Reuse already opened ssh connection

# 0.0.10

  * Support different backing strategies (copy, cow, direct, snapshot)
  * Add a mandatory project_id in the configuration

# 0.0.9

  * Add support for custom walltime

# 0.0.8

  * Add support for custom private key

# 0.0.7

  * Support for ephemeral / persitent backing file

# 0.0.6

  * SSH ports has to be forwarded explicitly

# 0.0.5

  * Add destroy command
  * Remove vmlist command

# 0.0.4

  * Use nat-ted network provided by kvm
  * Remove hard-coded names
