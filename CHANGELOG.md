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
