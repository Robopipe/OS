#!/bin/bash

DATA_PATH=${1:-"data"}
DESTINATION=${2:-"archive.swu"}

prepare-base-os() {
    if [ -f "${DATA_PATH}/base-os.zip" ];
    then
        echo "Base OS present"
        cp "${DATA_PATH}/base-os.zip" "base-os.zip"
    else
        echo "Downloading Base OS"
        wget https://kb.unipi.technology/_media/files:software:os-images:patron-base-os_12.20240917.1.zip -O base-os.zip
    fi

    unzip base-os.zip -d base-os && rm base-os.zip
    cd base-os
    mkdir archive && cd archive
    cpio -idm --no-absolute-filenames -I ../archive.swu && rm ../archive.swu
    mkdir root && cd root
    gzip -d ../root.cpio.gz && cpio -idm --no-absolute-filenames -I ../root.cpio && rm ../root.cpio
    cd ../../../
}

archive() {
    ARCHIVE_CONTENTS=("sw-description" "clearfs.sh" "root.cpio.gz" "boot.cpio.gz")

    cd base-os/archive/root
    find . -print -depth -mindepth 1 | cpio -o -H crc | gzip -c > ../root.cpio.gz
    cd ../
    echo "${ARCHIVE_CONTENTS[@]}" | tr " " "\n" | cpio -o -H crc > "../../archive.swu"
    cd ../../
    mv archive.swu "${DESTINATION}"
    rm -r base-os
}

configure_os() {
    _USERNAME="admin"

    mv /etc/resolv.conf /etc/resolv.conf.bak
    echo "nameserver 8.8.8.8" > /etc/resolv.conf

    mkdir -p /opt/robopipe/tools
    mkdir -p /etc/robopipe

    apt update && apt install -y pipx git nginx owserver avahi-utils
    apt install -y --no-install-recommends evok-unipi-data

    cp -r /home/unipi/ "/home/${_USERNAME}/"
    useradd -d "/home/${_USERNAME}" -s /bin/bash ${_USERNAME}
    echo "${_USERNAME}:robopipe.io" | chpasswd
    find "/home/${_USERNAME}/" -user root -exec chown ${_USERNAME}:${_USERNAME} {} \;
    usermod -aG sudo,unipi,dialout,i2c,spi,gpio ${_USERNAME}

    systemctl disable unipihostname
    cp /mnt/robopipehostname.service /etc/systemd/system/
    cp /mnt/set-robopipe-hostname.sh /opt/robopipe/tools/
    systemctl enable robopipehostname

    pipx ensurepath
    pipx install pipx
    apt purge --autoremove -y pipx
    ~/.local/bin/pipx install pipx --global
    . ~/.profile
    pipx uninstall pipx
    pipx ensurepath --global
    pipx install --global /mnt/robopipe_api-0.1.0.tar.gz
    cp /mnt/robopipeapi.service /etc/systemd/system/
    ln -s /etc/evok/hw_definitions /etc/robopipe/hw_definitions
    ln -s /etc/evok/autogen.yaml /etc/robopipe/autogen.yaml
    cp /mnt/controller-config.yaml /etc/robopipe/config.yaml
    cp /mnt/robopipe-api.env /etc/robopipe/.env
    echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="03e7", MODE="0666"' > /etc/udev/rules.d/80-movidius.rules
    systemctl enable robopipeapi

    openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/certs/server.key -out /etc/ssl/certs/server.cert \
    -sha256 -days 3650 -nodes \
    -subj "/CN=robopipe.local"
    cp /mnt/robopipe-api.conf /etc/nginx/sites-available/robopipe-api
    rm /etc/nginx/sites-enabled/default
    ln -s /etc/nginx/sites-available/robopipe-api /etc/nginx/sites-enabled/robopipe-api

    mv /etc/resolv.conf.bak /etc/resolv.conf
}

if [ ! -f "/etc/debian_version" ];
then
    echo "This script needs to be run on Debian OS"
    exit 1
fi

for dep in sudo wget unzip cpio;
do
    if ! command -v "${dep}" >/dev/null 2>&1;
    then
        if [ "${INSTALL_DEPS}" = "true" ];
        then
            apt update && apt install -y "${dep}"
        else
            echo "${dep} dependency is missing"
            exit 1
        fi
    fi
done

prepare-base-os
cd base-os/archive

mount -t proc /proc root/proc/
mount -t sysfs /sys root/sys/
mount -o bind /dev root/dev/
mount -o bind "${DATA_PATH}" root/mnt/

sudo chroot root /bin/sh -c "$(declare -f configure_os); configure_os"

umount root/proc/
umount root/sys/
umount root/dev/
umount root/mnt/

cd ../../

archive
