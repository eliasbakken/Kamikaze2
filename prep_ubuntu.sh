#!/bin/bash

WD=/usr/src/Kamikaze2/

network_fixes() {
	echo "Fixing network interface config..."
        sed -i 's/After=network.target auditd.service/After=auditd.service/' /etc/systemd/system/multi-user.target.wants/ssh.service
}

prep_ubuntu() {
	echo "Upgrading packages"
	apt-get update
	apt-get -y upgrade
	echo "** Preparing Ubuntu for kamikaze2 **"
	cd /opt/scripts/tools/
	git pull
	sh update_kernel.sh --bone-kernel --lts-4_1
	apt-get -y upgrade
	apt-get -y install unzip iptables
	mkdir -p /etc/pm/sleep.d
	touch /etc/pm/sleep.d/wireless
	sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
	apt-get purge linux-image-4.4.40-ti-r80 linux-image-4.9.3-armv7-x4
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
	echo "installing Kamikaze repo to the list"
	cat >/etc/apt/sources.list.d/testing.list <<EOL
#### Kamikaze ####
deb [arch=armhf] http://kamikaze.thing-printer.com/ubuntu/ xenial main
#deb [arch=armhf] http://kamikaze.thing-printer.com/debian/ stretch main
EOL
	wget -q http://kamikaze.thing-printer.com/ubuntu/public.gpg -O- | apt-key add -
#	wget -q http://kamikaze.thing-printer.com/debian/public.gpg -O- | apt-key add -
	apt-get update
}

fix_wlan() {
  apt-get -y install network-manager=1.2.2-0ubuntu0.16.04.3
  sed -i 's/^\[main\]/\[main\]\ndhcp=internal/' /etc/NetworkManager/NetworkManager.conf
  cp $WD/interfaces /etc/network/
}

cleanup() {
	apt-get remove -y libgtk-3-common
	apt-get autoremove -y
}

prep() {
	network_fixes
	prep_ubuntu
	remove_unneeded_packages
	install_repo
	fix_wlan
	cleanup
}

prep

echo "Now reboot into the new kernel and run make-kamikaze-2.1.sh"
