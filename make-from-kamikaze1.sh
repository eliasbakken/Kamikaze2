

install_prerequisites() {
	apt-get update
	apt-get install -y python-cairo python-gi-cairo
}


install_redeem() {
	cd /usr/src/
	git clone http://bitbucket.org/intelligentagent/redeem
	cd redeem
	git checkout develop
	make install_py
	cp systemd/* /lib/systemd/system/
	cp configs/* /etc/redeem/
	systemctl daemon-reload
	systemctl restart redeem
}


install_toggle() {
	cd /usr/src
	git clone http://bitbucket.org/intelligentagent/toggle
	cd toggle
	make libtoggle
	make install
	cp systemd/* /lib/systemd/system/
	cp configs/* /etc/toggle/
	systemctl daemon-reload
	systemctl restart toggle
}

install_octoprint() {
	cd /usr/src
	git clone https://github.com/foosel/OctoPrint
	cd OctoPrint
	python setup.py install
	sed -i.bak s:/usr/bin/octoprint:/usr/local/bin/octoprint:g /lib/systemd/system/octoprint.service
	systemctl daemon-reload
	systemctl restart octoprint
}

install_octoprint_redeem() {
	cd /usr/src/
	git clone https://github.com/eliasbakken/octoprint_redeem
	cd octoprint_redeem
	python setup.py install
}

install_octoprint_toggle() {
	cd /usr/src
	git clone https://github.com/eliasbakken/octoprint_toggle
	cd octoprint_toggle
	python setup.py install
}

install_prerequisites
install_redeem
install_toggle
install_octoprint
install_octoprint_redeem
install_octoprint_toggle
