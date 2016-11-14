#!/bin/bash

# This script is originally borrowed to pmorillo
# Thanks to him !
# I've made some addition though :) 

# ARGS
# $1: cpu demand
# $2: mem demand
# $3: net type {BRIDGE, NAT}
# BRIDGE | NAT
# $4 subnet_file  | $left other net, drive options
# $left net/drive options

set -x

function net_bridge() {
  SUBNET_FILE=$1
  # As we chose a stateless designe,let's calculate here the ip and mac
  # assuming we got a slash_22
  ipnumber=$(($OAR_JOB_ID % 1022))
  IP_MAC=$(cat $SUBNET_FILE|head -n $((ipnumber + 1))|tail -n 1)
  IP_ADDR=$(echo $IP_MAC|awk '{print $1}')
  MAC_ADDR=$(echo $IP_MAC|awk '{print $2}')

  # create tap
  TAP=$(sudo create_tap)

  # return the specific net string of the kvm command
  echo "-net nic,model=virtio,macaddr=$MAC_ADDR -net tap,ifname=$TAP,script=no"
}

# CPU demand
if [ "$1" == "-1" ]
then
  SMP=$(nproc)
else
  SMP=$1
fi
echo "SMP = $SMP"
shift

# Memory demand
KEEP_SYSTEM_MEM=1 # Gb
if [ "$1" == "-1" ]
then
  TOTAL_MEM=$(cat /proc/meminfo | grep -e '^MemTotal:' | awk '{print $2}')
  VM_MEM=$(( ($TOTAL_MEM / 1024) - $KEEP_SYSTEM_MEM * 1024 ))
else
  VM_MEM=$1
fi
echo "VM_MEM = $VM_MEM"
shift

# net demand
net=""
if [ "$1" == "BRIDGE" ]
then
  shift
  net=$(net_bridge $@)
  echo $(hostname)
  echo $net
  shift
else
  shift
  net=""
fi


# Directory for qcow2 snapshots
export TMPDIR=/tmp

# Clean shutdown of the VM at the end of the OAR job
clean_shutdown() {
  echo "Caught shutdown signal at $(date)"
  echo "system_powerdown" | nc -U /tmp/vagrant-g5k.mon
}

trap clean_shutdown 12

# Launch virtual machine
kvm -m $VM_MEM -smp cores=$SMP,threads=1,sockets=1 -fsdev local,security_model=none,id=fsdev0,path=$HOME -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare -nographic -monitor unix:/tmp/vagrant-g5k.mon,server,nowait -localtime -enable-kvm $net $@ &

wait

