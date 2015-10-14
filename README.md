# coreos
Installation script for CoreOS on Gandi server with gandi.cli

## original idea
"fork" from jmbarbier idea to create a cluster of coreos on Gandi vm : 
https://gist.github.com/jmbarbier/ab06cf23735845a0167a


## requirements
 - gandi.cli
 - credits on iaas account

## howto 

Download on local computer and make it executable : 

    $ wget https://raw.githubusercontent.com/azediv/gnadi-coreos/master/install-core.sh && chmod +x install-core.sh

Edit install-core.sh to change hostname, disk name, user and personalize cloud-config.yml configuration parameters
(etcd2, fleet, etc)

hostname must be short for now, 7 or 8 max due to the use of sys_$VM, disk name cannot be too long

Then run :

    $ ./install-core.sh

## files

### install-core.sh

install-core.sh is used locally with gandi.cli to create vm and install coreos with /gandi/config json file

json config is download and used to create cloud-config.yml

cloud-config.yml is scp to temp vm before install

details in script... (more soon)

## step by step process

### Resume

Creation of a Debian vm with a 10GB data disk.

Retrieve config of vm from /gandi/config.

Creation of cloud-config.yml file.

Installation of CoreOS from Debian vm on data disk.

Stop vm and detach of Debian disk.

Define kernel as raw on CoreOS disk 

Attach of CoreOS disk as system disk to vm.

Boot and enjoy

### Details:

$HOSTNAME define hostname of coreos vm.
$VM_USER define username for coreos vm.
$DC define datacenter for vm and disk 

Creation of Debian vm (512Mo at least, 256Mo isn't enough to install packages)

	$  gandi vm create --datacenter $DC --memory 512 --cores 1 --ip-version 4 --login $VM_USER --hostname $HOSTNAME --image "Debian 8 64 bits (HVM)" --size 3G

Creation of data (target of CoreOS install) and attachement to VM :

	$ gandi disk create --name core_sys --size 10G --datacenter $DC -vm $HOSTNAME

SSH to Debian :

	$ gandi vm ssh $HOSTNAME

Unmont data disk before installation :

	# umount /dev/sdc

Installation of wget

	# apt-get update && apt-get install -y wget 

Download of coreos install script :

	# wget https://raw.github.com/coreos/init/master/bin/coreos-install

Define as executable :

	# chmod +x coreos-install

Grab username, hashed password, sshkey of vm from /gandi/config json file : 

	VM_USER = cat /gandi/config| grep -Po '(?<="user": ")[^"]*' |head -1

	PASS : Hashed password can be used = cat /gandi/config | grep -Po '(?<="password": ")[^"]*'

	SSH = cat /gandi/config | grep -Po '(?<="ssh_key": ")[^"]*'

Grab network config of vm from /gandi/config json file : 

	HOSTNAME = cat /gandi/config| grep -Po '(?<="vm_hostname": ")[^"]*'

	IP = cat /gandi/config| grep -Po '(?<="pna_address": ")[^"]*' |head -1

	ROUTE = cat /gandi/config | grep -Po '(?<="pbn_gateway": ")[^"]*' | head -1

	DNS = gandi vm ssh $VM 'cat /etc/resolv.conf' | awk '{ print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1

Creation of cloud-config.yml file for CoreOS installation.

Contains static network, user, sshkey, units, etc...

Help : https://coreos.com/os/docs/latest/cloud-config.html#users


	# nano cloud-config.yml


	#cloud-config
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
	hostname: $HOSTNAME
	users:
	  - name: $VM_USER
	    passwd: $PASS
	    groups:
	      - sudo
	      - docker
	      
	    ssh_authorized_keys:
	      - $SSH


Starting CoreOS installation with cloud-config.yml

	# ./coreos-install -d /dev/sdc -C alpha -c cloud-config.yml

When installation is successfull, logout of Debian :

	# exit

Stop the Debian vm :

	$ gandi vm stop $HOSTNAME

Detach of system disk of Debian :

	$ gandi disk detach sys_$HOSTNAME

Detach of data disk, CoreOS :

	$ gandi disk detach core_sys

Update kernel to raw of data disk of CoreOS :

	$ gandi disk update --kernel raw core_sys

Attachement as system disk (-p 0) to vm :

	$ gandi disk attach -p 0 core_sys $HOSTNAME

First start of CoreOS on Gandi vm ! :

	$ gandi vm start $HOSTNAME

Remove previous SSH fingerprint for IP  :

	$ ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R $IP

Login to CoreOS :

	$ gandi vm ssh --login $VM_USER $HOSTNAME

Ping us ! :

	CoreOS alpha (829.0.0)
	$VM_USER@$HOSTNAME ~ $ ping gandi.net
	PING gandi.net (217.70.184.1) 56(84) bytes of data.
	64 bytes from website.vip.gandi.net (217.70.184.1): icmp_seq=1 ttl=60 time=104 ms
	64 bytes from website.vip.gandi.net (217.70.184.1): icmp_seq=2 ttl=60 time=104 ms
	^C
	--- gandi.net ping statistics ---
	2 packets transmitted, 2 received, 0% packet loss, time 1000ms
	rtt min/avg/max/mdev = 104.245/104.318/104.392/0.331 ms
	$VM_USER@$HOSTNAME ~ $ 

