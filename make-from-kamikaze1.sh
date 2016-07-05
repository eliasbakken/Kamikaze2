

install_prerequisites() {
	apt-get update
	apt-get install -y python-cairo
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


install_prerequisites
#install_redeem
install_toggle

