

make_test() {
	cd /usr/src/
	mkdir -p replicape/test/
	cd replicape/test/
	wget https://bitbucket.org/intelligentagent/replicape/raw/e23c1b5ff0d36cada56b9a67056e22a33ca7c25f/test/test.py
	wget https://bitbucket.org/intelligentagent/replicape/raw/e23c1b5ff0d36cada56b9a67056e22a33ca7c25f/test/test-replicape.service
	wget https://bitbucket.org/intelligentagent/replicape/raw/e23c1b5ff0d36cada56b9a67056e22a33ca7c25f/eeprom/Replicape_0B3A.eeprom
	wget https://bytebucket.org/intelligentagent/replicape/raw/e23c1b5ff0d36cada56b9a67056e22a33ca7c25f/test/error.png
	wget https://bytebucket.org/intelligentagent/replicape/raw/e23c1b5ff0d36cada56b9a67056e22a33ca7c25f/test/ok.png
	wget https://bitbucket.org/intelligentagent/replicape/raw/e23c1b5ff0d36cada56b9a67056e22a33ca7c25f/test/replicape.kmap
	cp test-replicape.service /lib/systemd/system
	systemctl enable test-replicape
	chmod +x test.py
	cd /etc/redeem
	ln -s testing_rev_B.cfg printer.cfg
}

make_test
