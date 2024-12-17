#!/bin/sh

HOSTNAME_PREFIX="robopipe-controller"
SEQUENCE_NUMBER="1"

while true;
do
    IP=$(avahi-resolve --name "${HOSTNAME_PREFIX}-${SEQUENCE_NUMBER}.local" 2>/dev/null | cut -f 2)

    if [ -n "${IP}" ]; then
        SEQUENCE_NUMBER=$((SEQUENCE_NUMBER + 1))
    else
        break
    fi
done

HOSTNAME="${HOSTNAME_PREFIX}-${SEQUENCE_NUMBER}"

hostnamectl set-hostname "${HOSTNAME}"
grep "${HOSTNAME}" /etc/hosts || echo "127.0.0.1 ${HOSTNAME}" >> /etc/hosts
/opt/unipi/tools/reconfigure-net
