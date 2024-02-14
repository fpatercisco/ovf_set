#!/bin/bash
# Configure the network using OVF/OVA vars -fpater@cisco 20240214
# ref: https://thevirtualist.org/creating-customizable-linux-ovf-template/

STATE_FILE=/root/.ovf_set_nmcli_ran

if [[ -e "$STATE_FILE ]]; then
	echo `date`' ovf_set_nmcli has already run (this is not first boot).'
	exit 1
fi

IP=`vmtoolsd --cmd 'info-get guestinfo.ovfenv' | egrep '<Property oe:key="ip"' | awk -F\" '{print $4}'`
NETMASK=`vmtoolsd --cmd 'info-get guestinfo.ovfenv' | egrep '<Property oe:key="netmask"' | awk -F\" '{print $4}'`
GATEWAY=`vmtoolsd --cmd 'info-get guestinfo.ovfenv' | egrep '<Property oe:key="gateway"' | awk -F\" '{print $4}'`
DNS=`vmtoolsd --cmd 'info-get guestinfo.ovfenv' | egrep '<Property oe:key="dns"' | awk -F\" '{print $4}'`
NEW_HOSTNAME=`vmtoolsd --cmd 'info-get guestinfo.ovfenv' | egrep '<Property oe:key="hostname"' | awk -F\" '{print $4}'`

echo `date`' guestinfo.ovfenv='`vmtoolsd --cmd 'info-get guestinfo.ovfenv'`
echo -e `date`"\nIP=$IP\nNETMASK=$NETMASK\nGATEWAY=$GATEWAY\nDNS=$DNS\nNEW_HOSTNAME=$NEW_HOSTNAME\n"

# grab the first ethernet interface
IFACE=`nmcli dev | egrep ' ethernet ' | head -n 1 | awk '{print $1}'`

# won't work for i.e. "Wired connection 1"...
CON=`nmcli con show | egrep "$IFACE"' *$' | head -n 1 | awk '{print $1}'`

nmcli con delete $CON

# Create new connection
# Check if IP and NETMASK variables exist and are not empty
if [[ -z "$IP" ]] && [[ -z "$NETMASK" ]]; then 
	nmcli con add con-name "$IFACE" ifname "$IFACE" type ethernet
else
	# If variables exist, configure interface with IP and netmask and GW. Also set DNS settings in same step.
	nmcli con add con-name "$IFACE" ifname "$IFACE" type ethernet ip4 "$IP"/"$NETMASK" gw4 "$GATEWAY" && echo "IP set to $IP/$NETMASK. GATEWAY set to $GATEWAY"
	nmcli con mod "$IFACE" ipv4.dns "$DNS" && echo "DNS set to $DNS"
fi

# set hostname
if [[ -n "$NEW_HOSTNAME" ]]; then
	hostnamectl set-hostname "$NEW_HOSTNAME" --static
fi

touch "$STATE_FILE"
