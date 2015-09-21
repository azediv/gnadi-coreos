## Description : 

Installation de CoreOS avec un kernel raw et une IP fixe sur une vm

## Résumé : 

Création d'une vm debian et d'un disque de données.

Récupération de la configuration réseau de Debian 

Création du fichier de config de CoreOS avec les infos de la Debian

Installation de CoreOS à partir de Debian sur le disque de données.

Détachement du disque Debian et du disuque CoreOS

Définition du kernel raw pour le disque CoreOS

Attachement du disque CoreOS en disque système

Boot and enjoy


## Etape par étape :

Création VM Debian 

    $ gandi vm create --datacenter US --memory 512 --cores 1 --ip-version 4   --hostname coreos --image "Debian 8 64 bits (HVM)" --size 3G


Création disque data (cible de l'install de CoreOS) et attachement à la VM :

    $ gandi disk create --name core_sys --size 10G --datacenter US -vm coreos


Connexion SSH à Debian pour effectuer l'installation et récupérer la configuration de l'interface réseau eth0 :

    $ gandi vm ssh coreos


Démontage du disque data avant l'installation :

    # umount /dev/sdc


Installation des mises à jour et de wget : # curl est présent sur les images au pire

    # apt-get update && apt-get install -y wget 


Récupération du fichier d'install de CoreOS

    # wget https://raw.github.com/coreos/init/master/bin/coreos-install


Définir le fichier comme exécutable :

    # chmod +x coreos-install


Récupération de l'IPv4 :

    # ifconfig |grep -A 1 eth0

    eth0      Link encap:Ethernet    
    inet addr:173.246.XX.XX
          

Récupération de la gateway (default) :

    # route |grep default

default         173.246.XX.XX    0 eth0


Récupération du DNS :

    # cat /etc/resolv.conf 

    nameserver 2604:3400:dc1
    nameserver 173.246.XX.X
    nameserver 173.246.XX.XX


Création du fichier cloud-config.yml pour l'installation de CoreOS.
Contient la configuration réseau static (avec un stop, la config et un start du service(unit systemd-networkd.service)) 
un user avec pass hashé (mkpasswd, openssl, etc...)
une clé ssh
https://coreos.com/os/docs/latest/cloud-config.html#users

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
            DNS=173.246.XX.XX
            Address=173.246.XX.XX
            Gateway=173.246.XX.XX
        - name: systemd-networkd.service
          command: start
          
    users:
      - name: core_user
        passwd: $hashed_password
        groups:
          - sudo
          
        ssh_authorized_keys:
          - ssh-rsa blablacar
      

Lancement de l'installation sur le disque avec le fichier de config :

    # ./coreos-install -d /dev/sdc -C alpha -c cloud-config.yml


Quand l'installation est terminée, sortie de la vm Debian :

    # exit


Arrêt de la VM Debian

    $ gandi vm stop coreos


Détachement du disque système Debian :

    $ gandi disk detach sys_coreos


Détachement du disque data CoreOS :

    $ gandi disk detach core_sys


Mise à jour du noyau (kernel raw) du disque de data CoreOS :

    $ gandi disk update --kernel raw core_sys


Attachement en disque système (-p 0) du disque CoreOS à la VM :

    $ gandi disk attach -p 0 core_sys coreos


Démarrage de la VM CoreOS :

    $ gandi vm start coreos


Suppression de l'ancienne empreinte SSH : 

    $ ssh-keygen -f "/home/local_user/.ssh/known_hosts" -R 173.246.XX.XX


Connexion à la VM CoreOS :

    $ gandi vm ssh --login core_user coreos

    CoreOS alpha (808.0.0)
    core_user@localhost ~ $ ip a

    2: eth0: 
        inet 173.246.XX.XX eth0
        inet6 2604:3400:dc1.XX.XX 

    core_user@localhost ~ $ ping gandi.net

    PING gandi.net (217.70.184.1) 56(84) bytes of data.
    64 bytes from website.vip.gandi.net (217.70.184.1): icmp_seq=1 ttl=60 time=104 ms
    64 bytes from website.vip.gandi.net (217.70.184.1): icmp_seq=2 ttl=60 time=104 ms
    ^C
    --- gandi.net ping statistics ---
    2 packets transmitted, 2 received, 0% packet loss, time 1000ms
    rtt min/avg/max/mdev = 104.245/104.318/104.392/0.331 ms

