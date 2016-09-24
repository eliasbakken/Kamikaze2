#!/bin/bash

# TODO 2.1: 
# PCA9685 in devicetree
# Make redeem dependencies built into redeem
# Remove xcb/X11 dependencies
# Add sources to clutter packages
# Slic3r support
# Edit Cura profiles

# TODO 2.0:
# Sync Redeem master with develop. 
# /dev/ttyGS0

# STAGING: 
# redeem starts after spidev2.1
# Adafruit lib disregard overlay (Swithed to spidev)
# cura engine
# iptables-persistent
# clear cache
# Update dogtag
# Update Redeem / Toggle

# DONE: 
# consoleblank=0
# sgx-install after changing kernel
# Custom uboot
# redeem plugin
# Toggle plugin
# Install libyaml

VERSION="Kamikaze 2.0.6"
DATE=`date`
echo "**Making ${VERSION}**"

export LC_ALL=C

remove_unneeded_packages() {
    echo "** Remove unneded packages **" 

    rm -rf /etc/apache2/sites-enabled
    rm -rf /root/.c9
    rm -rf /usr/local/lib/node_modules
    rm -rf /var/lib/cloud9
    rm -rf /usr/lib/node_modules/
    apt-get purge -y \
    bone101 nodejs \
    apache2 apache2-bin \
    apache2-data apache2-utils vim \
    linux-headers-4.4.19-ti-r41 \
    ti-pru-cgt-installer \
    doc-beaglebonegreen-getting-started \
    doc-seeed-bbgw-getting-started \
	doc-beaglebone-getting-started
}


upgrade_to_stretch() {
    echo "** Upgrade to stretch **" 

    sed -i 's/jessie/stretch/' /etc/apt/sources.list
	sed -i 's%deb https://deb.nodesource.com/node_0.12 stretch main%#deb https://deb.nodesource.com/node_0.12 stretch main%' /etc/apt/sources.list	

    cat >/etc/apt/sources.list.d/testing.list <<EOL
#### Kamikaze ####  
deb [arch=armhf] http://kamikaze.thing-printer.com/debian/ stretch main
EOL

	
    wget -q http://kamikaze.thing-printer.com/debian/public.gpg -O- | apt-key add -
	apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
}


install_dependencies(){
    echo "** Install dependencies **" 
	apt-get install -y \
	swig \
	socat \
	ti-sgx-es8-modules-4.4.20-bone13 \
	libyaml-dev \
    gir1.2-mash-0.3-0 \
    gir1.2-mx-2.0 \
	libclutter-imcontext-0.1-0 \
	libcluttergesture-0.0.2-0 \
    python-scipy \
    python-smbus \
    python-gi-cairo
	pip install evdev
	pip install spidev

	apt-get purge -y \
	linux-image-4.4.19-ti-r41 \
	rtl8723bu-modules-4.4.19-ti-r41

}

install_redeem() {
    echo "**install_octoprint_redeem**" 
	cd /usr/src/
    if [ ! -d "redeem" ]; then
	    git clone https://bitbucket.org/intelligentagent/redeem
    fi    
	cd redeem
    git pull
	git checkout develop
	make install

    # Make profiles uploadable via Octoprint
	touch /etc/redeem/local.cfg
	chown -R octo:octo /etc/redeem/
	chown -R octo:octo .git

	cd /usr/src/Kamikaze2

	# Install rules
	cp scripts/spidev.rules /etc/udev/rules.d/

	# Install Kamikaze2 specific systemd script
	cp scripts/redeem.service /lib/systemd/system
	systemctl enable redeem
	systemctl start redeem
}

create_user() {
	default_groups="admin,adm,dialout,i2c,kmem,spi,cdrom,floppy,audio,dip,video,netdev,plugdev,users,systemd-journal,tisdk,weston-launch,xenomai"
	mkdir /home/octo/
	mkdir /home/octo/.octoprint
	useradd -G "${default_groups}" -s /bin/bash -m -p octo -c "OctoPrint" octo
	chown -R octo:octo /home/octo
	chown -R octo:octo /usr/local/lib/python2.7/dist-packages
	chown -R octo:octo /usr/local/bin
	chmod 755 -R /usr/local/lib/python2.7/dist-packages
}

install_octoprint() {
	cd /home/octo
	su - octo -c 'git clone https://github.com/foosel/OctoPrint.git'
	su - octo -c 'cd OctoPrint && python setup.py clean install'
}

post_octoprint() {
	cd /usr/src/Kamikaze2
	# Make config file for Octoprint
	cp OctoPrint/config.yaml /home/octo/.octoprint/
	chown octo:octo "/home/octo/.octoprint/config.yaml"

	# Fix permissions for STL upload folder
	mkdir -p /usr/share/models
	chown octo:octo /usr/share/models
	chmod 777 /usr/share/models

	# Grant octo redeem restart rights
	echo "%octo ALL=NOPASSWD: /bin/systemctl restart redeem.service" >> /etc/sudoers
	echo "%octo ALL=NOPASSWD: /bin/systemctl restart toggle.service" >> /etc/sudoers

    echo "%octo ALL=NOPASSWD: /usr/bin/make -C /usr/src/redeem install" >> /etc/sudoers
    echo "%octo ALL=NOPASSWD: /usr/bin/make -C /usr/src/toggle install" >> /etc/sudoers

	# Port forwarding
	/sbin/iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 5000
	mkdir -p /etc/iptables
	iptables-save > /etc/iptables/rules	
	cat >/etc/network/if-pre-up.d/iptables <<EOL
#!/bin/sh
/sbin/iptables-restore < /etc/iptables/rules
EOL
	chmod +x /etc/network/if-pre-up.d/iptables

	# Install systemd script
	cp ./OctoPrint/octoprint.service /lib/systemd/system/
	systemctl enable octoprint
	systemctl start octoprint
}

install_octoprint_redeem() {
	echo "**install_octoprint_redeem**" 
	cd /usr/src/
	if [ ! -d "octoprint_redeem" ]; then
		git clone https://github.com/eliasbakken/octoprint_redeem
	fi
	cd octoprint_redeem
	python setup.py install
}

install_octoprint_toggle() {
	echo "**install_octoprint_toggle**" 
	cd /usr/src
	if [ ! -d "octoprint_toggle" ]; then
		git clone https://github.com/eliasbakken/octoprint_toggle
	fi
	cd octoprint_toggle
	python setup.py install
}

install_overlays() {
	echo "**install_overlays**" 
	cd /usr/src/
	if [ ! -d "bb.org-overlays" ]; then
		git clone https://github.com/eliasbakken/bb.org-overlays
	fi
	cd bb.org-overlays
	./install.sh 
}

install_sgx() {
	cd /usr/src/Kamikaze2
	tar xfv GFX_5.01.01.02_es8.x.tar.gz -C /
	cd /opt/gfxinstall/
	./sgx-install.sh
	cd /usr/src/Kamikaze2/
	cp scripts/sgx-startup.service /lib/systemd/system/
	systemctl enable sgx-startup.service
	depmod -a 4.4.20-bone13
	ln -s /usr/lib/libEGL.so /usr/lib/libEGL.so.1
}


install_toggle() {
	cd /usr/src
    if [ ! -d "toggle" ]; then
	    git clone https://bitbucket.org/intelligentagent/toggle
    fi
	cd toggle
	make install
	cp systemd/toggle.service /lib/systemd/system/
	systemctl enable toggle
	systemctl start toggle
}

install_cura() {
	cd /usr/src/
	git clone https://github.com/Ultimaker/CuraEngine
	cd CuraEngine/
	git checkout  tags/15.04.6 -b tmp
	make
	cp build/CuraEngine /usr/bin/

	# Copy profiles into Cura.
	cd /usr/src/Kamikaze2
	mkdir -p /home/octo/.octoprint/slicingProfiles/cura/
	cp ./Cura/profiles/*.profile /home/octo/.octoprint/slicingProfiles/cura/
	chown octo:octo /home/octo/.octoprint/slicingProfiles/cura/
}


install_uboot() {
	cd /usr/src/Kamikaze2
	export DISK=/dev/mmcblk0
	dd if=./u-boot/MLO of=${DISK} count=1 seek=1 bs=128k
	dd if=./u-boot/u-boot.img of=${DISK} count=2 seek=1 bs=384k
}

other() {
	sed -i 's/cape_universal=enable/consoleblank=0 fbcon=rotate:1 omap_wdt.nowayout=0/' /boot/uEnv.txt	
	sed -i 's/beaglebone/kamikaze/' /etc/hostname
	sed -i 's/beaglebone/kamikaze/g' /etc/hosts
    sed -i 's/AcceptEnv LANG LC_*/#AcceptEnv LANG LC_*/'  /etc/ssh/sshd_config

	apt-get clean
	apt-get autoclean
	rm -rf /var/cache/doc*
	apt-get -y autoremove
	echo "$VERSION $DATE" > /etc/dogtag
}



dist() {
	remove_unneeded_packages
	upgrade_to_stretch    
	install_sgx
	install_dependencies    
	install_redeem
	create_user
	install_octoprint
	post_octoprint
	install_octoprint_redeem
	install_octoprint_toggle
	install_overlays
	install_toggle
	install_cura
	install_uboot
	other
}


dist

echo "Now reboot!"

