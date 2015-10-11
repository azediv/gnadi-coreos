#!/bin/bash

# Define settings of coreos vm

VM=vmcore
VM_USER=usercore
DC=US
DISK=diskcore

# Create temp vm to attach data disk as target of coreos install script

gandi vm create --datacenter $DC --memory 512 --cores 1 --ip-version 4  --hostname $VM --image 'Debian 8 64 bits (HVM)' --login $VM_USER --password

wait

# Create data disk to attach to vm

gandi disk create --name $DISK --size 10G --datacenter $DC --vm $VM

sleep 30

# Define local user to add/remove ssh fingerprint

LUSER=`echo $USER`

# Get vm IP

IP=`gandi vm info $VM | grep ip4 | sed 's/ip4 *: //g'`

wait

# Remove fingerprint if IP already known

ssh-keygen -f /home/$LUSER/.ssh/known_hosts -R $IP

# Download of gandi config file containing all informations about vm

scp root@$IP:/gandi/config ./config

wait

# Define from gandi config file : route, hashed password, ssh key, dns

ROUTE=`cat config | grep -Po '(?<="pbn_gateway": ")[^"]*' | head -1`

PASS=`cat config | grep -Po '(?<="password": ")[^"]*'`

SSH=`cat config | grep -Po '(?<="ssh_key": ")[^"]*'`

DNS=`gandi vm ssh $VM 'cat /etc/resolv.conf' | awk '{ print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1`

wait

# Creation of cloud-config.yml file

printf "#cloud-config
coreos:
  units:
    - name: systemd-networkd.service
      command: stop
    - name: 00-eth0.network
      runtime: true
      content: |
        [Match]
        Name=eth0

        [Network]
        DNS=$DNS
        Address=$IP
        Gateway=$ROUTE
    - name: systemd-networkd.service
      command: start
hostname: $VM
users:
  - name: $VM_USER
    passwd: $PASS
    groups:
      - sudo

    ssh_authorized_keys:
      - $SSH\n" > cloud-config.yml

wait

# Upload of cloud-config.yml file

scp cloud-config.yml root@$IP:/root/

wait

# Unmount of data disk  before installation of CoreOS
# Install of wget 
# Download  of coreos-install script
# Installation of coreos from cloud-config file

gandi vm ssh $VM "umount /dev/sdc;\

apt-get update && apt-get install -y wget &&\

wget https://raw.github.com/coreos/init/master/bin/coreos-install &&\

chmod +x coreos-install &&\

./coreos-install -d /dev/sdc -C alpha -c cloud-config.yml &&\

exit"

wait

# Stop of vm before detaching disks

gandi vm stop $VM

wait

# Detach both disk

gandi disk detach -f sys_$VM

wait

gandi disk detach -f $DISK

wait

# Update kernel of CoreOS disk as raw

gandi disk update --kernel raw $DISK

wait

# Attach CoreOS disk in first position

gandi disk attach -f -p 0 $DISK $VM

wait

# Delete Debian disk

gandi disk delete -f sys_$VM

wait

# Start CoreOS vm

gandi vm start $VM

wait

# Remove previous ssh fingerprint

ssh-keygen -f /home/$LUSER/.ssh/known_hosts -R $IP

# Connect via SSH to CoreOS new vm

gandi vm ssh --login $VM_USER $VM

