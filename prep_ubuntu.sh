#!/bin/bash
set -x

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
	sh update_kernel.sh --bone-kernel --lts-4_4
	apt-get -y upgrade
	apt-get -y install unzip iptables
	sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
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

wlan_fixes() {
	echo "** Install wireless firmware **"
	#add BBB wireless firmware for wireless boards.
	git clone --depth 1 git://git.ti.com/wilink8-wlan/wl18xx_fw.git /usr/src/wl18xx_fw
	cp /usr/src/wl18xx_fw/wl18xx-fw-4.bin /lib/firmware/ti-connectivity/
	rm -rf /usr/src/wl18xx_fw/

	echo "** Disable wireless power management **"
	mkdir -p /etc/pm/sleep.d
	touch /etc/pm/sleep.d/wireless

	echo "** Install Network Manager 1.2.4 **"
	#This module is a workaround for the network manager 1.2.4 install
	wget http://launchpadlibrarian.net/299750846/network-manager_1.2.4-0ubuntu0.16.04.1_armhf.deb -P $WD
	apt-get -y remove connman
	dpkg -i $WD/network-manager_1.2.4-0ubuntu0.16.04.1_armhf.deb
        ln -s /run/resolvconf/resolv.conf /etc/resolv.conf
	dhclient eth0
	dhclient wlan0
	apt-get install -yf
	sed -i 's/^\[main\]/\[main\]\ndhcp=internal/' /etc/NetworkManager/NetworkManager.conf
	cp $WD/interfaces /etc/network/
}

remove_unneeded_packages() {
	echo "** Remove unneded packages **"*
	rm -rf /etc/apache2/sites-enabled
	rm -rf /root/.c9
	rm -rf /usr/local/lib/node_modules
	rm -rf /var/lib/cloud9
	rm -rf /usr/lib/node_modules/
	apt-get purge -y apache2 apache2-bin apache2-data apache2-utils
}

cleanup() {
	apt-get remove -y libgtk-3-common bb-wl18xx-firmware
	apt-get autoremove -y
}

prep() {
	network_fixes
	prep_ubuntu
	install_repo
	wlan_fixes
	remove_unneeded_packages
	cleanup
}

prep

echo "Now reboot into the new kernel and run make-kamikaze-2.1.sh"

