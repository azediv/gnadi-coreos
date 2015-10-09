#!/bin/bash

VM=coreos

DC=US

# Création VM Debian (au moins 512Mo, 256Mo pas suffisant pour install des packages)

gandi vm create --datacenter $DC --memory 512 --cores 1 --ip-version 4  --hostname $VM --image 'Debian 8 64 bits (HVM)'

wait

# Création disque data (cible de l'install de CoreOS) et attachement à la VM :

gandi disk create --name core_sys --size 10G --datacenter $DC --vm $VM

wait

# Connexion SSH à Debian (pour effectuer l'installation et récupérer la configuration de l'interface réseau eth0) :

# Démontage du disque data avant l'installation :

gandi vm ssh $VM "umount /dev/sdc;\

apt-get update && apt-get install -y wget &&\

wget https://raw.github.com/coreos/init/master/bin/coreos-install &&\

wget https://raw.githubusercontent.com/azediv/gnadi-coreos/master/if-core-config.sh &&\

chmod +x if-core-config.sh &&\

chmod +x coreos-install"

IP=`gandi vm info $VM | grep ip4 | sed 's/ip4 *: //g'`

printf "ssh_authorized_keys:\n - " > base_cloud_config.yml

cat ~/.ssh/id_rsa.pub >> base_cloud_config.yml

scp base_cloud_config.yml root@$IP:/root/base-cloud-config.yml

gandi vm ssh $VM "./if-core-config.sh &&\

cat base-cloud-config.yml >> cloud-config.yml
