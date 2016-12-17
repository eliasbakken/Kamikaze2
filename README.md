# Kamikaze2
Simplified Kamikaze image generation

The starting point for Kamikaze 2.1.0 is the Ubuntu console image found here: 
http://elinux.org/BeagleBoardUbuntu#eMMC:_BeagleBone_Black.2FGreen

To create Kamikaze 2.1:
    
    disable the eMMC flasher on the SD image first!
    ssh ubuntu@arm (password: temppwd)
    sudo su -
    passwd (set root password to kamikaze)
    cd /usr/src
    git clone http://github.com/eliasbakken/Kamikaze2
    cd Kamikaze2
    bash prep_ubuntu.sh
    reboot the BBB from the SD again
    ssh ubuntu@arm (password: temppwd)
    sudo su -
    cd /usr/src/Kamikaze2/
    bash make-kamikaze-2.1.sh

The starting point for Kamikaze 2.0.0 is the Debian IoT image found here: 
https://debian.beagleboard.org/images/

For Kamikaze 1.0:  
    ssh root@kamikaze.local  
    cd /usr/src/  
    git clone http://github.org/eliasbakken/Kamikaze2  
    cd Kamikaze2  
    ./make-kamikaze-1.1.1.sh  

Here is how to recreate for Kamikaze 2.0:  
    ssh root@beaglebone.local  
    cd /usr/src/  
    git clone http://github.org/eliasbakken/Kamikaze2  
    cd Kamikaze2  
    ./make-kamikaze-2.0.0.sh  


The update command will kick the user out from the ssh session. 

Changelog: 
2.0.0 - Kernel 4.4.20-bone13, cogl-1.22, clutter-1.26

1.1.1 - chown octo:octo on /etc/redeem and /etc/toggle

1.1.0 - Install latest Redeem, Toggle and OctoPrint from repositories. 


