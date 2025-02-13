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
        wget -nv --header="User-Agent: Mozilla/5.0" https://kb.unipi.technology/_media/files:software:os-images:patron-base-os_12.20240917.1.zip -O base-os.zip
    fi

    unzip base-os.zip -d base-os && rm base-os.zip
    cd base-os
    mkdir archive && cd archive
    cpio -idm --no-absolute-filenames -I ../archive.swu && rm ../archive.swu
    mkdir root && cd root
    gzip -d ../root.cpio.gz && cpio -idm --no-absolute-filenames -I ../root.cpio && rm ../root.cpio
    cd ../
    mkdir boot && cd boot
    gzip -d ../boot.cpio.gz && cpio -idm --no-absolute-filenames -I ../boot.cpio && rm ../boot.cpio
    cd ../../../
}

prepare-packages() {
    ROBOPIPE_API_REPO="Robopipe/API"
    ROBOPIPE_API_RES=$(wget -qO- "https://api.github.com/repos/${ROBOPIPE_API_REPO}/releases/latest")
    ROBOPIPE_API_RELEASE=$(echo "${ROBOPIPE_API_RES}" | jq -r '.assets[] | select(.name | endswith("tar.gz")) | .browser_download_url')

    export ROBOPIPE_API="robopipe-api.tar.gz"
    wget -nv "${ROBOPIPE_API_RELEASE}" -O "${DATA_PATH}/${ROBOPIPE_API}"
}

cleanup() {
    rm "${DATA_PATH}/${ROBOPIPE_API}"
}

archive() {
    ARCHIVE_CONTENTS=("sw-description" "clearfs.sh" "root.cpio.gz" "boot.cpio.gz")

    cd base-os/archive/root
    find . -print -depth -mindepth 1 | cpio -o -H crc | gzip -c > ../root.cpio.gz
    cd ../boot
    find . -print -depth -mindepth 1 | cpio -o -H newc | gzip -c > ../boot.cpio.gz
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

    # User configuration
    cp -r /home/unipi/ "/home/${_USERNAME}/"
    useradd -d "/home/${_USERNAME}" -s /bin/bash ${_USERNAME}
    echo "${_USERNAME}:robopipe.io" | chpasswd
    find "/home/${_USERNAME}/" -user root -exec chown ${_USERNAME}:${_USERNAME} {} \;
    usermod -aG sudo,unipi,dialout,i2c,spi,gpio ${_USERNAME}

    # Hostname service
    systemctl disable unipihostname
    cp /mnt/robopipehostname.service /etc/systemd/system/
    cp /mnt/set-robopipe-hostname.sh /opt/robopipe/tools/
    systemctl enable robopipehostname

    # Pipx configuration
    pipx ensurepath
    pipx install pipx
    apt purge --autoremove -y pipx
    ~/.local/bin/pipx install pipx --global
    . ~/.profile
    pipx uninstall pipx
    pipx ensurepath --global

    # Robopipe API configuration
    pipx install --global "/mnt/${ROBOPIPE_API}"
    ln -s /etc/evok/hw_definitions /etc/robopipe/hw_definitions
    ln -s /etc/evok/autogen.yaml /etc/robopipe/autogen.yaml
    cp /mnt/controller-config.yaml /etc/robopipe/config.yaml
    cp /mnt/robopipe-api.env /etc/robopipe/.env
    echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="03e7", MODE="0666"' > /etc/udev/rules.d/80-movidius.rules
    cp /mnt/robopipeapi.service /etc/systemd/system/
    systemctl enable robopipeapi

    # Nginx configuration
    openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/certs/server.key -out /etc/ssl/certs/server.cert \
    -sha256 -days 3650 -nodes \
    -subj "/CN=robopipe.local"
    cp /mnt/robopipe-api.conf /etc/nginx/sites-available/robopipe-api
    rm /etc/nginx/sites-enabled/default
    ln -s /etc/nginx/sites-available/robopipe-api /etc/nginx/sites-enabled/robopipe-api

    mv /etc/resolv.conf.bak /etc/resolv.conf
}

configure_boot() {
    INITRD="initrd.img-6.1.55"

    cd boot/altboot
    mv "${INITRD}" "${INITRD}.gz"
    gzip -d "${INITRD}.gz"
    mkdir initrd && cd initrd
    cpio -imd -I "../${INITRD}" && rm "../${INITRD}"

    cd opt/swu
    tar -xzf webapp.tar.gz && rm webapp.tar.gz
    
    cp "${DATA_PATH}/service-index.html" index.html
    cp "${DATA_PATH}/robopipe-logo.svg" images/logo.svg
    cp "${DATA_PATH}/favicon.png" images/favicon.png

    tar --remove-files -czf webapp.tar.gz $(ls | grep -Ev "swupdate|ttyd")
    cd ../../

    find . | cpio -o -H newc | gzip -9 -n > "../${INITRD}"
    cd ../
    rm -rf "initrd"
    chmod 755 "${INITRD}"
    cd ../../
}

if [ ! -f "/etc/debian_version" ];
then
    echo "This script needs to be run on Debian OS"
    exit 1
fi

for dep in sudo wget unzip cpio jq;
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
prepare-packages
cd base-os/archive

mount -t proc /proc root/proc/
mount -t sysfs /sys root/sys/
mount -o bind /dev root/dev/
mount -o bind "${DATA_PATH}" root/mnt/

sudo chroot root /bin/sh -c "ROBOPIPE_API=${ROBOPIPE_API}; $(declare -f configure_os); configure_os"

umount root/proc/
umount root/sys/
umount root/dev/
umount root/mnt/

configure_boot

cd ../../

archive
cleanup
