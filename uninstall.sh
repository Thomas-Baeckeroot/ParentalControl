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

sudo gvfs-trash /root/limit-usage-time.sh
echo $?
sudo gvfs-trash /root/*-rollover-date.cfg
echo $?
sudo gvfs-trash /root/*-time-left.cfg
echo $?

ADMIN=`cat /root/parental_control_admin.cfg`
USERS_AND_TIMES_FILE=/home/$ADMIN/users_and_times.cfg
sudo gvfs-trash $USERS_AND_TIMES_FILE
echo $?

exit 0

