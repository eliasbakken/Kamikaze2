#!/bin/bash

# TODO 2.1: 
# PCA9685 in devicetree

# TODO 2.0:
# Make redeem dependencies built into redeem
# Custom uboot
# sgx-install after changing kernel

# STAGING: 
# Adafruit lib disregard overlay (Swithed to spidev)
# consoleblank=0

# DONE: 


echo "Making Kamikaze 2.0.1"

export LC_ALL=C

add_testing_branch() {
	cat >/etc/apt/preferences.d/security.pref <<EOL
Package: *
Pin: release l=Debian-Security
Pin-Priority: 1000
EOL
	cat >/etc/apt/preferences.d/stable.pref <<EOL
Package: *
Pin: release a=stable
Pin-Priority: 900
EOL
	cat >/etc/apt/preferences.d/testing.pref <<EOL
Package: *
Pin: release a=testing
Pin-Priority: 750
EOL
	cat >/etc/apt/preferences.d/unstable.pref <<EOL
Package: *
Pin: release a=unstable
Pin-Priority: 50
EOL
	cat >/etc/apt/preferences.d/experimental.pref <<EOL
Package: *
Pin: release a=experimental
Pin-Priority: 1
EOL

	cat >/etc/apt/sources.list.d/testing.list <<EOL
deb http://httpredir.debian.org/debian/ testing main contrib non-free
deb-src http://httpredir.debian.org/debian/ testing main contrib non-free
EOL

}

stop_services() {
	systemctl disable apache2
	systemctl stop apache2
	systemctl disable bonescript-autorun.service
	systemctl stop bonescript-autorun.service
	systemctl disable bonescript.socket
	systemctl stop bonescript.socket
	systemctl disable bonescript.service
	systemctl stop bonescript.service
}

install_dependencies(){
	apt-get update --fix-missing
	apt-get upgrade -y
	apt-get install -y \
	swig \
	cura-engine \
	iptables-persistent \
	socat \
	ti-sgx-es8-modules-4.4.20-bone13 \
	gnome-common gtk-doc-tools \
	gobject-introspection \
	python-gobject \
	libgirepository1.0-dev \
	python-cairo \
	libgles2-mesa-dev \
	libpangocairo-1.0-0 \
	libevdev-dev \
	libmtdev-dev \
	python-scipy
	pip install evdev
	pip install spidev
}

install_redeem() {
	cd /usr/src/
	git clone https://bitbucket.org/intelligentagent/redeem
	cd redeem
	git checkout develop
	make install
}

post_redeem() {
	cd /usr/src/redeem
	# Make profiles uploadable via Octoprint
	mkdir -p /etc/redeem
	cp configs/*.cfg /etc/redeem/
	cp data/*.cht /etc/redeem/
	touch /etc/redeem/local.cfg
	chown -R octo:octo /etc/redeem/

	# Install systemd script
	cp systemd/redeem.service /lib/systemd/system
	systemctl enable redeem
	systemctl start redeem
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

	# Port forwarding
	/sbin/iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 5000
	/usr/sbin/netfilter-persistent save

	# Install systemd script
	cp ./OctoPrint/octoprint.service /lib/systemd/system/
	systemctl enable octoprint
	systemctl start octoprint
}

install_overlays() {
	cd /usr/src/
	git clone https://github.com/eliasbakken/bb.org-overlays
	cd bb.org-overlays
	./install.sh 
}

install_sgx() {
	cd /usr/src/Kamikaze2
	tar xfv GFX_5.01.01.02_es8.x.tar.gz -C /
	cd /opt/gfxinstall/
	./sgx-install.sh
	depmod -a 4.4.20-bone13
}

install_cogl() {
	cd /usr/src
	apt-get build-dep -t testing cogl
	apt-get source -t testing cogl
	cd cogl-1.22.2/
	./configure --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf/ --enable-introspection --disable-gles1 --enable-cairo --disable-gl --enable-gles2 --enable-null-egl-platform --enable-cogl-pango
	make
	make install
}

install_clutter() {
	cd /usr/src
	#apt-get build-dep -t testing clutter
	apt-get source -t testing clutter
	cd clutter-1.0-1.26.0
	./configure --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf/ --disable-x11-backend  --enable-egl-backend --enable-evdev-input --disable-gdk-backend
	make
	make install
}

install_mx() {
	cd /usr/src
	git clone https://github.com/clutter-project/mx.git
	cd mx
	./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf/ --with-winsys=none --disable-gtk-doc --enable-introspection
	make
	make install
}

install_mash() {
	cd /usr/src
	git clone https://github.com/eliasbakken/mash.git
	cd /usr/src/mash
	./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf/ --enable-introspection
	sed -i 's:--library=mash-@MASH_API_VERSION@:--library=mash-@MASH_API_VERSION@ \ --library-path=/usr/src/mash/mash/.libs/:' mash/Makefile.am
	make CFLAGS="`pkg-config --cflags clutter-1.0`"
	make install
}

install_toggle() {
    cd /usr/src
    git clone https://bitbucket.org/intelligentagent/toggle
    cd toggle
    make install
}

post_toggle() {
    cd /usr/src/toggle
    cp systemd/toggle.service /lib/systemd/system/
    systemctl enable toggle
    systemctl start toggle
}

post_cura() {
    # Copy profiles into Cura.
    cd /usr/src/Kamikaze2
    mkdir -p /home/octo/.octoprint/slicingProfiles/cura/
    cp ./Cura/profiles/*.profile /home/octo/.octoprint/slicingProfiles/cura/
    chown octo:octo /home/octo/.octoprint/slicingProfiles/cura/
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

other() {
    sed -i 's/cape_universal=enable/consoleblank=0 fbcon=rotate:1 omap_wdt.nowayout=0/' /boot/uEnv.txt	
	sed -i 's/beaglebone/kamikaze/' /etc/hostname
}


stop_services
install_dependencies
install_redeem
post_redeem
create_user
install_octoprint
post_octoprint
install_overlays
install_sgx
install_cogl
install_clutter
install_mx
install_mash
install_toggle
post_toggle
post_cura
other

echo "Now reboot!"

