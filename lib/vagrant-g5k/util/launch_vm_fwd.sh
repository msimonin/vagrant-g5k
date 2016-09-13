#!/bin/bash
#OAR -l slash_22=1+{virtual!='none'}/nodes=1,walltime=06:00:00
#OAR --checkpoint 60
#OAR --signal 12

# Directory for qcow2 snapshots
export TMPDIR=/tmp
#IMAGE=/grid5000/virt-images/alpine-docker.qcow2

# GET Virtual IP information
IP_ADDR=$(/usr/local/bin/g5k-subnets -im | head -1 | awk '{print $1}')
MAC_ADDR=$(/usr/local/bin/g5k-subnets -im | head -1 | awk '{print $2}')

echo "VM IP informations :"
echo "IP address: $IP_ADDR"
echo "MAC address: $MAC_ADDR"

# Create tap
TAP=$(sudo create_tap)

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
#kvm -m $VM_MEM -smp $SMP -drive file=/grid5000/images/KVM/alpine_docker.qcow2,if=virtio -snapshot -fsdev local,security_model=none,id=fsdev0,path=$HOME -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare -nographic -net nic,model=virtio,macaddr=$MAC_ADDR -net tap,ifname=$TAP,script=no -monitor unix:/tmp/alpine_docker_vm.mon,server,nowait -localtime -enable-kvm &
#kvm -m $VM_MEM -smp $SMP -drive file=$IMAGE,if=virtio -snapshot -fsdev local,security_model=none,id=fsdev0,path=$HOME -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare -nographic -net nic,model=virtio,macaddr=$MAC_ADDR -net tap,ifname=$TAP,script=no -monitor unix:/tmp/vagrant-g5k.mon,server,nowait -localtime -enable-kvm &
kvm -m $VM_MEM -smp $SMP -snapshot -fsdev local,security_model=none,id=fsdev0,path=$HOME -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare -nographic -monitor unix:/tmp/vagrant-g5k.mon,server,nowait -localtime -enable-kvm $@ &

wait

