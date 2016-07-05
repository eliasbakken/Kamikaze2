

install_prerequisites() {
	apt-get update
	apt-get install -y python-cairo python-gi-cairo
	pip install virtualenv
}


install_redeem() {
	cd /usr/src/
	if [ ! -d "redeem" ]; then
		git clone http://bitbucket.org/intelligentagent/redeem
	fi
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
	if [ ! -d "toggle" ]; then
		git clone http://bitbucket.org/intelligentagent/toggle
	fi
	cd toggle
	make libtoggle
	make install
	cp systemd/* /lib/systemd/system/
	cp configs/* /etc/toggle/
	systemctl daemon-reload
	systemctl restart toggle
}

make_venv() {
        cd /usr/src/
	mkdir venv
	chown octo:octo venv
	chmod 755 venv
        sudo -u octo virtualenv venv
}


install_octoprint() {
	cd /usr/src
	if [ ! -d "OctoPrint" ]; then
		git clone https://github.com/foosel/OctoPrint
	fi
	cd OctoPrint
	chown -R octo:octo .
	chmod -R 755 .
	sudo -u octo /usr/src/venv/bin/python setup.py install
	sed -i.bak s:/usr/bin/octoprint:/usr/src/venv/bin/octoprint:g /lib/systemd/system/octoprint.service
	systemctl daemon-reload
	systemctl restart octoprint
}

install_octoprint_redeem() {
	cd /usr/src/
	if [ ! -d "octoprint_redeem" ]; then
		git clone https://github.com/eliasbakken/octoprint_redeem
	fi
	cd octoprint_redeem
	chown -R octo:octo .
        chmod -R 755 .
        sudo -u octo /usr/src/venv/bin/python setup.py install
}

install_octoprint_toggle() {
	cd /usr/src
	if [ ! -d "octoprint_toggle" ]; then
		git clone https://github.com/eliasbakken/octoprint_toggle
	fi
	cd octoprint_toggle
	chown -R octo:octo .
        chmod -R 755 .
	sudo -u octo /usr/src/venv/bin/python setup.py install
}

#install_prerequisites
#install_redeem
#install_toggle
#make_venv
#install_octoprint
#install_octoprint_redeem
install_octoprint_toggle
