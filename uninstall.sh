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
echo
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
echo
echo "Moving to trash /root/limit-usage-time.sh ..."
sudo gvfs-trash /root/limit-usage-time.sh
#echo $?
# Users of the machine (non-system, not weird, etc):
VICTIMS=`awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534) print $1}' /etc/passwd`
for VICTIM in $VICTIMS; do
echo "Moving to trash /root/$VICTIM-rollover-date.cfg and /root/$VICTIM-time-left.cfg ..."
	sudo gvfs-trash /root/$VICTIM-rollover-date.cfg
	#echo $?
	sudo gvfs-trash /root/$VICTIM-time-left.cfg
	#echo $?
	# TODO: guest-*-rollover-date.cfg and guest-*-time-left.cfg may need to be deleted also...
done

ADMIN=`sudo cat /root/parental_control_admin.cfg`
USERS_AND_TIMES_FILE=/home/$ADMIN/users_and_times.cfg
echo "Moving to trash $USERS_AND_TIMES_FILE ..."
sudo gvfs-trash $USERS_AND_TIMES_FILE
#echo $?
echo "Moving to trash /root/parental_control_admin.cfg ..."
sudo gvfs-trash /root/parental_control_admin.cfg

echo "Terminated."
exit 0

