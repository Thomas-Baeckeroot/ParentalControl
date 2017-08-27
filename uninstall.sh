#!/bin/bash

#####
#
# Project       : Poor man's parental control - uninstall scripts
# Started       : August 27, 2017
# Last Modified : August, 2017
# Author        : Thomas Baeckeroot
# Module        : uninstall.sh
# Description   : Uninstalls the "Poor man's parental control" from the computer.

set +x
echo "- Uninstall scripts for Parental Time Control -"
echo
echo "This script will remove files and remove"
echo "configuration -crontab- from your system."

sudo gvfs-trash /root/limit-usage-time.sh
echo $?

echo "Check if limit-usage-time.sh has been added to cron..."
sudo crontab -l | grep limit-usage-time.sh > nul
if [ "$?" == "0" ]; then
	echo "Parental control script in cron. Removing..."
        sudo crontab -l | grep -v /root/limit-usage-time.sh > /tmp/modified_crontab.cron
        # Programming crontab back without limit-usage-time.sh:
        sudo crontab /tmp/modified_crontab.cron
else
	echo "limit-usage-time.sh not detected in cron, no need to remove."
fi

# TODO Check from below, might just be deleted
echo ""
echo "Known users of this machine:"
# Users of the machine (non-system, not weird, etc):
awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534) print $1}' /etc/passwd
echo ""

defaultadmin=`who am i | awk '{print $1}'`
# workaround in case previous did not worked ( gnome-terminal issue )
if [ "$defaultadmin" == "" ]; then
	term=`tty`
	defaultadmin=`ls -l $term | awk '{print $3}'`
fi

read -p "Define user who would be administrator [default=$defaultadmin] :" adminuser
if [ "$adminuser" == "" ]; then
	adminuser=$defaultadmin
fi



exit 0

