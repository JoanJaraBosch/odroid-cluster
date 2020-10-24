#!/bin/bash

scripts_path="$(cat /etc/odroid_cluster.conf | grep "SCRIPTS_DIR" | cut -d= -f2)"
upgrade_slave="$(cat /etc/odroid_cluster.conf | grep "UPGRADE" | cut -d= -f2)"

# Carreguem el script network_lib.sh com a una llibreria, per 
#	poder fer servir les seves funcions
source network_lib.sh

# Evitem que es guardi el password al historial
export HISTIGNORE=$HISTIGNORE':*sudo -S*:*sshpass*'


default_password=$(cat /etc/odroid_cluster.conf | grep "DEFAULT_PASSWORD" | cut -d= -f2)
# Agafem el nom de l'usuari no root
master_name=$(cat /etc/odroid_cluster.conf | grep "DEFAULT_USER" | cut -d= -f2)
# Agafem el directori home l'usuari no root
master_home=$(eval echo "~$master_name")

KEY_FILE="${master_home}/.ssh/id_rsa.pub"
KNOWN_HOSTS="${master_home}/.ssh/known_hosts"

host="$1" # $1 la ip del slave
name="$2" # $2 nom del slave
passphrase="$3" # $4 passphrase

# Comprovem que es passi com a minim 3 parametres
if [ $# -lt 2 ]; then
	echo -e "Error, at least you have to enter 3 parameters, for more information \n\t add_slave -h"
	exit 1
fi


# Afegim el fingerprint al fitxer de hosts coneguts
su $master_name -c "echo \"$(ssh-keyscan -H $host)\" >> $KNOWN_HOSTS"

# Copiem la clau publica al slave
su $master_name -c "sshpass -p $default_password ssh-copy-id -i $KEY_FILE $name@$host"

# Copiem el script de inicialització al slave
su $master_name -c "sshpass -p ${default_password} scp ${scripts_path}/init_slave.sh ${name}@${host}:Documents"

# Agafem la IP de la xarxa interna
interface="$(cat /etc/dnsmasq.conf | grep interface= | cut -d= -f2)"
master_ip="$(get_ip_of_nic $interface)"

# Executem el script de inicialització al slave
su $master_name -c "sshpass -p ${default_password} ssh -t ${name}@${host} \"echo ${default_password} | sudo -S ~/Documents/init_slave.sh $master_ip $upgrade_slave \" >> /tmp/init_slave_${host}.out 2>&1"


