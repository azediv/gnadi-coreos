#!/bin/bash

# Define settings of coreos vm

VM=corevm
USER=coreuser
DC=US
DISK=coredisk

gandi vm create --datacenter $DC --memory 512 --cores 1 --ip-version 4  --hostname $VM --image 'Debian 8 64 bits (HVM)' --login $USER --password

wait

gandi disk create --name $DISK --size 10G --datacenter $DC --vm $VM

wait

IP=`gandi vm info $VM | grep ip4 | sed 's/ip4 *: //g'`

wait

ssh-keygen -f "~/.ssh/known_hosts" -R $IP

scp root@$IP:/gandi/config ./config

wait

ROUTE=`cat config | grep -Po '(?<="pbn_gateway": ")[^"]*' | head -1`

PASS=`cat config | grep -Po '(?<="password": ")[^"]*'`

SSH=`cat config | grep -Po '(?<="ssh_key": ")[^"]*'`

DNS=`gandi vm ssh $VM 'cat /etc/resolv.conf' | awk '{ print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1`

wait

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
  - name: $USER
    passwd: $PASS
    groups:
      - sudo

    ssh_authorized_keys:
      - $SSH\n" > cloud-config.yml

wait

scp cloud-config.yml root@$IP:/root/

wait

gandi vm ssh $VM "umount /dev/sdc;\

apt-get update && apt-get install -y wget &&\

wget https://raw.github.com/coreos/init/master/bin/coreos-install &&\

chmod +x coreos-install &&\

./coreos-install -d /dev/sdc -C alpha -c cloud-config.yml &&\

exit"

wait

gandi vm stop $VM

wait

gandi disk detach sys_$VM

wait

gandi disk detach $DISK

wait

gandi disk update --kernel raw $DISK 

wait

gandi disk attach -p 0 $DISK $VM 

wait

gandi disk delete sys_$VM

wait

gandi vm start $VM

wait

ssh-keygen -f ~/.ssh/known_hosts -R $IP

gandi vm ssh --login $USER $VM
