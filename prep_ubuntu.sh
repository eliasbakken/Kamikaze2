#!/bin/bash

prep_ubuntu() {
	apt-get update
	apt-get -y upgrade
	echo "** Preparing Ubuntu for kamikaze2 **"
	cd /opt/scripts/tools/
	git pull
	sh update_kernel.sh --bone-kernel --lts-4_1
	touch /etc/pm/sleep.d/wireless
	apt-get -y install unzip iptables
	sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
}

remove_unneeded_packages() {
	echo "** Remove unneded packages **" 

	rm -rf /etc/apache2/sites-enabled
	rm -rf /root/.c9
	rm -rf /usr/local/lib/node_modules
	rm -rf /var/lib/cloud9
	rm -rf /usr/lib/node_modules/
	apt-get purge -y apache2 apache2-bin apache2-data apache2-utils
}

install_repo() {
	cat >/etc/apt/sources.list.d/testing.list <<EOL
#### Kamikaze ####
deb [arch=armhf] http://kamikaze.thing-printer.com/debian/ stretch main
EOL
	wget -q http://kamikaze.thing-printer.com/debian/public.gpg -O- | apt-key add -
	apt-get update
}

prep_ubuntu
remove_unneeded_packages
install_repo
reboot
