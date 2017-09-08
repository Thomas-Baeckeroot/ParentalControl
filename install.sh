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
echo
sudo cp limit-usage-time.sh /root/ || echo "An ERROR or WARNING occurred when copying script to root folder!"
sudo chmod u+x /root/limit-usage-time.sh || echo "An ERROR or WARNING occurred when setting execution rights on script!"

echo "Check if limit-usage-time.sh has already been added to cron:"
sudo crontab -l | grep limit-usage-time.sh > nul
if [ "$?" == "0" ]; then
	echo "Parental control script already in cron... Probably not the first time this install script is ran."
else
	echo "limit-usage-time.sh not detected in cron, adding it..."
	sudo crontab -l > /tmp/modified_crontab.cron
	# Adding below line to run every minute:
	echo '* * * * * /root/limit-usage-time.sh' >>/tmp/modified_crontab.cron
	#echo '* * * * * /root/limit-usage-time.sh >> /tmp/limit-usage-time.log 2>&1' >>/tmp/modified_crontab.cron
	sudo crontab /tmp/modified_crontab.cron
fi

# Users of the machine (non-system, not weird, etc):
VICTIMS=`awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534) print $1}' /etc/passwd`
echo ""
echo "Known users of this machine:"
echo $VICTIMS
echo ""

defaultadmin=`who am i | awk '{print $1}'`
# workaround in case previous did not worked ( gnome-terminal issue )
if [ "$defaultadmin" == "" ]; then
	term=`tty`
	defaultadmin=`ls -l $term | awk '{print $3}'`
fi
PREVIOUS_ADMIN=`sudo cat /root/parental_control_admin.cfg`
if [ "PREVIOUS_ADMIN" != "" ]; then
	echo "Information: '$PREVIOUS_ADMIN' as been previously informed as administrator."
fi
read -p "Define user who would be administrator [default=$defaultadmin] :" ADMIN
if [ "$ADMIN" == "" ]; then
	ADMIN=$defaultadmin
fi
sudo echo $ADMIN >/tmp/parental_control_admin.cfg
sudo mv /tmp/parental_control_admin.cfg /root/parental_control_admin.cfg

# creates configuration files in admin user's home folder:
USERS_AND_TIMES_FILE=/home/$ADMIN/users_and_times.cfg

echo "# found at http://forums.linuxmint.com/viewtopic.php?f=213&t=77687" >$USERS_AND_TIMES_FILE
echo "# Configuration file containing usernames" >>$USERS_AND_TIMES_FILE
echo "# and their corresponding alloted time." >>$USERS_AND_TIMES_FILE
echo "# Format: <login-name> <allocated minutes>" >>$USERS_AND_TIMES_FILE
echo >>$USERS_AND_TIMES_FILE
echo
echo "What should be the time limit for each user, in minutes per day?"
echo "- a default value of 60 minutes per day will be used if none informed -"
for VICTIM in $VICTIMS; do
	DEFAULT_TIME_LIMIT=60
	if [ "$VICTIM" == "$ADMIN" ]; then
		DEFAULT_TIME_LIMIT=9999
		echo "Note that $DEFAULT_TIME_LIMIT is informed for administrator in"
		echo "configuration file but this value is actually ignored..."
	fi
	read -p "Time limit in minutes for user $VICTIM [default=$DEFAULT_TIME_LIMIT] :" TIME_LIMIT
	if [ "$TIME_LIMIT" == "" ]; then
		TIME_LIMIT=$DEFAULT_TIME_LIMIT
	fi
	echo "$VICTIM $TIME_LIMIT" >>$USERS_AND_TIMES_FILE
	# We're done for this victim!
done
# We're done for all victims!
sudo chown $ADMIN:$ADMIN $USERS_AND_TIMES_FILE
echo
echo "Configuration file created in $USERS_AND_TIMES_FILE ."
echo "Terminated."
exit 0

