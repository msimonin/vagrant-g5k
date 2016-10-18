#!/bin/bash

# This script is borrowed from pmorrillon.
# Thanks to him !

#OAR -l slash_22=1+{virtual!='none'}/nodes=1,walltime=06:00:00
#OAR --checkpoint 60
#OAR --signal 12

set -x

SUBNET_FILE=$1
shift

# As we chose a stateless designe,let's calculate here the ip and mac
# assuming we got a slash_22
ipnumber=$(($OAR_JOB_ID % 1022))
IP_MAC=$(cat $SUBNET_FILE|head -n $((ipnumber + 1))|tail -n 1)
IP_ADDR=$(echo $IP_MAC|awk '{print $1}')
MAC_ADDR=$(echo $IP_MAC|awk '{print $2}')

echo $(hostname)
echo "VM IP informations :"
echo "SUBNET_FILE: $SUBNET_FILE"
echo "OAR_JOB_ID : $OAR_JOB_ID"
echo "ipnumber: $ipnumber"
echo "IP_MAC: $IP_MAC"
echo "IP address: $IP_ADDR"
echo "MAC address: $MAC_ADDR"

# create tap
TAP=$(sudo create_tap)

# Directory for qcow2 snapshots
export TMPDIR=/tmp

# Memory allocation
KEEP_SYSTEM_MEM=1 # Gb
TOTAL_MEM=$(cat /proc/meminfo | grep -e '^MemTotal:' | awk '{print $2}')
VM_MEM=$(( ($TOTAL_MEM / 1024) - $KEEP_SYSTEM_MEM * 1024 ))

# CPU
SMP=$(nproc)

# Clean shutdown of the VM at the end of the OAR job
clean_shutdown() {
  echo "Caught shutdown signal at $(date)"
  echo "system_powerdown" | nc -U /tmp/vagrant-g5k.mon
}

trap clean_shutdown 12

# Launch virtual machine
#kvm -m $VM_MEM -smp $SMP -drive file=$IMAGE,if=virtio -snapshot -fsdev local,security_model=none,id=fsdev0,path=$HOME -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare -nographic -net nic,model=virtio,macaddr=$MAC_ADDR -net tap,ifname=$TAP,script=no -monitor unix:/tmp/vagrant-g5k.mon,server,nowait -localtime -enable-kvm &
kvm -m $VM_MEM -smp $SMP -fsdev local,security_model=none,id=fsdev0,path=$HOME -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare -nographic -monitor unix:/tmp/vagrant-g5k.mon,server,nowait -localtime -enable-kvm -net nic,model=virtio,macaddr=$MAC_ADDR -net tap,ifname=$TAP,script=no $@ &

wait

