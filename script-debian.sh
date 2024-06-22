#!/bin/bash

# The script was initially designed to work on Fedora, and was forked + tweaked to run on Debian / Ubuntu
# This was made for the Surface Pro 7+, though running the script might also work on your computer. 
# In essence, all it does is automate the instructions from https://github.com/linux-surface/linux-surface/wiki/Installation-and-Setup#Debian--Ubuntu
# Good luck, and enjoy

if [ "$UID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    # clone the repositories
    git clone https://github.com/quo/ithc-linux ~/ithc-linux
    git clone https://github.com/linux-surface/iptsd ~/iptsd

    # add the Linux Surface signing keys
    wget -qO - https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/linux-surface.gpg
    
    # add the Linux Surface repository
    echo "deb [arch=amd64] https://pkg.surfacelinux.com/debian release main" | sudo tee /etc/apt/sources.list.d/linux-surface.list
    sudo apt update

    # install dkms and meson
    sudo apt install dkms meson build-essential -y

    # cd into ithc-linux and run make dkms-install
    cd ~/ithc-linux
    sudo make dkms-install

    # add ithc to modprobe
    echo "ithc" | sudo tee -a /etc/modules-load.d/ithc.conf

    # install kernel needed
    sudo apt install linux-image-surface linux-headers-surface libwacom-surface -y

    # adding secure boot
    sudo apt install linux-surface-secureboot-mok

    # cd into iptsd and run meson build, then ninja -C build
    cd ~/iptsd
    meson build
    ninja -C build

    # find hidraw device
    hidrawN=$(sudo ./etc/iptsd-find-hidraw)

    # create daemon script
    mkdir ~/.daemonscript
    echo "sudo ./build/src/daemon/iptsd $hidrawN" > ~/.daemonscript/iptsdscript.sh

    # edit grub config
    sudo sed -i "s/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\\\"rhgb intremap=nosid '~\/.daemonscript\/iptsdscript.sh' quiet\\\"/g" /etc/default/grub
    sudo update-grub

    # explictly warn about secureboot password
    echo "Please remember the password you set for secure boot. It should be 'surface', but scrool up and check."
    echo "You will need it to enroll the MOK key, which will be required as soon as you reboot!"
fi