#!/bin/bash

#####
#
# Project       : Poor man's parental control - install scripts
# Started       : August 07, 2017
# Last Modified : August, 2017
# Author        : Thomas Baeckeroot
# Module        : install.sh
# Description   : Installs the "Poor man's parental control" on the computer.

set +x
echo "- Install script for Parental Time Control -"
echo
echo "This script will copy files to the right place,"
echo "configure your system and"
echo "guide you through the simple configuration."


sudo cp limit-usage-time.sh /root/
echo $?
sudo chmod u+x /root/limit-usage-time.sh
echo $?

echo "Check if limit-usage-time.sh has already been added to cron..."
sudo crontab -l | grep limit-usage-time.sh > nul
if [ "$?" == "0" ]; then
	echo "Parental control script already in cron... Probably not the first time this install script is ran"
else
	echo "limit-usage-time.sh not detected in cron, adding it..."
	sudo crontab -l > /tmp/modified_crontab.cron
	# Adding below line to run every minute:
	echo '* * * * * /root/limit-usage-time.sh' >>/tmp/modified_crontab.cron
	sudo crontab /tmp/modified_crontab.cron
fi

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

