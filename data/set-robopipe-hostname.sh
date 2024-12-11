#!/bin/sh

HOSTNAME_PREFIX="robopipe-controller"
SERIAL=$(python3 /opt/unipi/os-configurator/os-configurator.py | grep '^UNIPI_PRODUCT_SERIAL=' | cut -d'=' -f2 | tr -d "'")
HOSTNAME="${HOSTNAME_PREFIX}-${SERIAL}"

hostnamectl set-hostname "${HOSTNAME}"
grep "${HOSTNAME}" /etc/hosts || echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts
/opt/unipi/tools/reconfigure-net
