#!/bin/sh

IFACE="eth0"
LEASEFILE="/run/dhcp-test-$IFACE.leases"
PIDFILE="/run/dhcp-test-$IFACE.pid"

OUTPUT=$(timeout 5 dhclient -1 -v -sf /bin/true -pf "$PIDFILE" -lf "$LEASEFILE" "$IFACE" 2>&1)

if [ $? -eq 0 ]; then
    echo "DHCP is available"
    systemctl stop isc-dhcp-server
else
    echo "DHCP is not available"
    systemctl start isc-dhcp-server
fi

echo "$OUTPUT"
