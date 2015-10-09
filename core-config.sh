#!/bin/bash

# core-install script with /gandi/config file

# Define vm hostname user datacenter and disk name

VM=coreos
USER=coruser
DC=US
DISK=coresys

# Create VM Debian (min 512Mo, 256Mo is not enough to install packages)

gandi vm create --datacenter $DC --memory 512 --cores 1 --ip-version 4  --hostname $VM --image 'Debian 8 64 bits (HVM)' --login $USER --password

wait

# disk creation and attach to vm as coreos-install.sh target 

gandi disk create --name $DISK --size 10G --datacenter $DC --vm $VM

wait

# SSH to Debian vm
# unmount coreos disk before installation
# download coreos-install
# download cloud-config.sh 
# chmod +x both and run them to install

gandi vm ssh $VM "umount /dev/sdc;\

apt-get update && apt-get install -y wget &&\

wget https://raw.github.com/coreos/init/master/bin/coreos-install &&\

wget https://raw.githubusercontent.com/azediv/gnadi-coreos/master/cloud-config.sh &&\

chmod +x cloud-config.sh &&\

chmod +x coreos-install &&\

./cloud-config.sh &&\

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

gandi vm start $VM

wait

IP=`gandi vm info $VM | grep ip4 | sed 's/ip4 *: //g'`

ssh-keygen -f ~/.ssh/known_hosts -R $IP

gandi vm ssh --login $USER $VM



