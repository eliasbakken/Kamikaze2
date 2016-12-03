#!/bin/bash

# TODO 2.1: 
# PCA9685 in devicetree
# Make redeem dependencies built into redeem
# Remove xcb/X11 dependencies
# Add sources to clutter packages
# Slic3r support
# Edit Cura profiles
# Remove root access 
# /dev/ttyGS0

# TODO 2.0:
# After boot, 
# initrd img / depmod-a on new kernel. 

# STAGING: 
# Copy uboot files to /boot/uboot
# Restart commands on install for Redeem and Toggle
# Update to Clutter 1.26.0+dsfg-1

# DONE: 
# consoleblank=0
# sgx-install after changing kernel
# Custom uboot
# redeem plugin
# Toggle plugin
# Install libyaml
# redeem starts after spidev2.1
# Adafruit lib disregard overlay (Swithed to spidev)
# cura engine
# iptables-persistenthttps://github.com/eliasbakken/Kamikaze2/releases/tag/v2.0.7rc1
# clear cache
# Update dogtag
# Update Redeem / Toggle
# Sync Redeem master with develop.  	
# Choose Toggle config

VERSION="Kamikaze 2.0.9"
DATE=`date`
echo "**Making ${VERSION}**"

export LC_ALL=C

prep_ubuntu() {
	echo "** Preparing Ubuntu for kamikaze2 **"
	cd /opt/scripts/tools/
	git pull
	sh update_kernel.sh --bone-kernel --lts-4_1
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

port_forwarding() {
	echo "** Port Forwarding **"
	# Port forwarding
	/sbin/iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 5000
	mkdir -p /etc/iptables
	iptables-save > /etc/iptables/rules
	cat >/etc/network/if-pre-up.d/iptables <<EOL
#!/bin/sh
/sbin/iptables-restore < /etc/iptables/rules
EOL
	chmod +x /etc/network/if-pre-up.d/iptables
}

install_dependencies(){
	echo "** Install dependencies **"
	apt-get install -y \
	python-pip
	network-manager\
	swig \
	socat \
	ti-sgx-es8-modules-`uname -r` \
	libyaml-dev \
	gir1.2-mash-0.3-0 \
	gir1.2-mx-2.0 \
	libclutter-imcontext-0.1-0 \
	libcluttergesture-0.0.2-0 \
	python-scipy \
	python-smbus \
	python-gi-cairo \
	libavahi-compat-libdnssd1 
	pip install evdev
	pip install spidev
	pip install Adafruit_BBIO

	wget https://github.com/beagleboard/am335x_pru_package/archive/master.zip
	unzip master.zip
	# install pasm PRU compiler
	mkdir /usr/include/pruss
	cd am335x_pru_package-master/
	cp pru_sw/app_loader/include/prussdrv.h /usr/include/pruss/
	cp pru_sw/app_loader/include/pruss_intc_mapping.h /usr/include/pruss
	chmod 555 /usr/include/pruss/*
	cd pru_sw/app_loader/interface
	CROSS_COMPILE= make
	cp ../lib/* /usr/lib
	ldconfig
	cd ../../utils/pasm_source/
	source linuxbuild
	cp ../pasm /usr/bin/
	chmod +x /usr/bin/pasm

	apt-get purge -y \
	linux-image-4.4.30-ti-r66\
	rtl8723bu-modules-4.4.30-ti-r66
}

install_redeem() {
	echo "**install_redeem**" 
	cd /usr/src/
	if [ ! -d "redeem" ]; then
		git clone https://bitbucket.org/intelligentagent/redeem
	fi    
	cd redeem
	git pull
	make install

	# Make profiles uploadable via Octoprint
	touch /etc/redeem/local.cfg
	chown -R octo:octo /etc/redeem/
	chown -R octo:octo /usr/src/redeem/

	cd /usr/src/Kamikaze2

	# Install rules
	cp scripts/spidev.rules /etc/udev/rules.d/

	# Install Kamikaze2 specific systemd script
	cp scripts/redeem.service /lib/systemd/system
	systemctl enable redeem
	systemctl start redeem
}

create_user() {
	echo "** Create user **" 
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
	echo "** Install OctoPrint **" 
	cd /home/octo
    if [ ! -d "OctoPrint" ]; then
	    su - octo -c 'git clone https://github.com/foosel/OctoPrint.git'
    fi
	su - octo -c 'cd OctoPrint && python setup.py clean install'

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
	echo "** install SGX **" 
	cd /usr/src/Kamikaze2
	tar xfv GFX_5.01.01.02_es8.x.tar.gz -C /
	cd /opt/gfxinstall/
	./sgx-install.sh
	cd /usr/src/Kamikaze2/
	cp scripts/sgx-startup.service /lib/systemd/system/
	systemctl enable sgx-startup.service
	depmod -a `uname -r`
	ln -s /usr/lib/libEGL.so /usr/lib/libEGL.so.1
}


install_toggle() {
	echo "** install toggle **" 
	cd /usr/src
    	if [ ! -d "toggle" ]; then
		git clone https://bitbucket.org/intelligentagent/toggle
    	fi
	cd toggle
	make install
	chown -R octo:octo /etc/toggle/
	# Make it writable for updates
	chown -R octo:octo /usr/src/toggle/
	cp systemd/toggle.service /lib/systemd/system/
	systemctl enable toggle
	systemctl start toggle
}

install_cura() {
	echo "** install Cura **" 
	cd /usr/src/
	if [ ! -d "CuraEngine" ]; then
		git clone https://github.com/Ultimaker/CuraEngine
	fi
	cd CuraEngine/
	git checkout  tags/15.04.6 -b tmp
	# Do perimeters first 
	sed -i 's/SETTING(perimeterBeforeInfill, 0);/SETTING(perimeterBeforeInfill, 1);/' src/settings.cpp
	make
	cp build/CuraEngine /usr/bin/

	# Copy profiles into Cura.
	cd /usr/src/Kamikaze2
	mkdir -p /home/octo/.octoprint/slicingProfiles/cura/
	cp ./Cura/profiles/*.profile /home/octo/.octoprint/slicingProfiles/cura/
	chown octo:octo /home/octo/.octoprint/slicingProfiles/cura/
}


install_uboot() {
	echo "** install U-boot**" 
	cd /usr/src/Kamikaze2
	export DISK=/dev/mmcblk0
	dd if=./u-boot/MLO of=${DISK} count=1 seek=1 bs=128k
	dd if=./u-boot/u-boot.img of=${DISK} count=2 seek=1 bs=384k
    cp ./u-boot/MLO /boot/uboot/
    cp ./u-boot/u-boot.img /boot/uboot/ 
}

other() {
	sed -i 's/cape_universal=enable/consoleblank=0 fbcon=rotate:1 omap_wdt.nowayout=0/' /boot/uEnv.txt	
	sed -i 's/arm/kamikaze/' /etc/hostname
	sed -i 's/arm/kamikaze/g' /etc/hosts
	sed -i 's/AcceptEnv LANG LC_*/#AcceptEnv LANG LC_*/'  /etc/ssh/sshd_config

	chown -R octo:octo /usr/src/Kamikaze2

	apt-get clean
	apt-get autoclean
	rm -rf /var/cache/doc*
	apt-get -y autoremove
	echo "$VERSION $DATE" > /etc/dogtag
}

dist() {
	remove_unneeded_packages
	install_repo
	port_forwarding
	install_dependencies
	install_sgx
	create_user
	install_redeem
	install_octoprint
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

