#!/bin/bash
# run this on the source of an OVA before shutting down, it will leave you with a "gold template" image.
# credit: https://www.reddit.com/r/linuxadmin/comments/bkxe7s/comment/eml5ezk/ 

# stop logging
service rsyslog stop
service auditd stop

# remove old kernels -- needs yum-utils
package-cleanup --old-kernels --count=1

# clean up yum
yum clean all

# clean up logs
logrotate -f /etc/logrotate.conf
rm -f /var/log/*-????????
rm -f /var/log/*.gz
rm -f /var/log/dmesg.old
rm -rf /var/log/anaconda

# trunc audit logs

cat /dev/null > /var/log/audit/audit.log
cat /dev/null > /var/log/wtmp
cat /dev/null > /var/log/lastlog
cat /dev/null > /var/log/grubby

# clean udev
rm -f /etc/udev/rules.d/70*

# clean nic configs
sed -i '/^(HWADDR|UUID)=/d' /etc/sysconfig/network-scripts/ifcfg-e*

# clean /tmp
rm -rf /tmp/*
rm -rf /var/tmp/*

# ssh and root
rm -f /etc/ssh/*key*
rm -f /root/.bash_history
unset HISTFILE

rm -rf /root/.ssh
rm -f /root/anaconda-ks.cfg
