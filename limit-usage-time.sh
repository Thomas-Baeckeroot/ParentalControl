#!/bin/bash

#####
#
# Project       : Poor man's parental control
#                 Limiting a user's daily computer usage time
# Started       : May 12, 2011
# Last Modified : March, 2015
# Author        : Anthony David (Pilosopong Tasyo)
# Author (minor): Thomas Baeckeroot
# Module        : limit-usage-time.sh
# Description   : Monitors the amount of time a user spends on the computer then
#                 locks the screen when the limit has been reached.
#                 This script is run as a cron job (executed once per minute).
#
# To install it, run ./install.sh
# Further explancations at http://forums.linuxmint.com/viewtopic.php?f=213&t=77687
#
# Previous script version (copied from Anthony David) was not working fully on my PC, so I modified it.
# I aimed to be as generic as possible but I am not sure what is specific to my configuration and what is not.
# This script worked fine with:
# - Linux Mint 17.1 Xfce, 18.1 Xfce (with a configuration that uses more than one X terminal).
#
# Comment by ganamant » […] "CD/USB booting should be disabled on the BIOS, too"
#
##########

# To debug a cron job (as this script), inform the cron line with the "2>&1" tag, as per below example:
# * * * * * /root/limit-usage-time.sh >> /tmp/limit-usage-time.log 2>&1
echo -----------------------------------------------------------
echo `date`
echo Running $0 with user $USER
set -x


# Some useful variables
# ADMIN = login name of the computer's administrator.
ADMIN=`cat /root/parental_control_admin.cfg`

# Date- and time-keeping variables.
TODAY=`date +%D`
YESTERDAY=0
TIME_LEFT=0

# Shortcuts to configuration files.
USERS_AND_TIMES_FILE=/home/$ADMIN/users_and_times.cfg

# Who's currently logged in:
#VICTIMS=`users`        # Issue: if user launches multiple terminals, he appears multiple times... (ssh in, …)
#VICTIMS=`ps -aux | grep xinitrc | grep -v 'grep\|root\|$ADMIN' | cut -f 1 -d ' '` # By extracting user with X session
#VICTIMS=`ps -aux | grep wm | grep -v "grep\|root\|$ADMIN" | cut -f 1 -d ' '` # By extracting users who started a Window Manager
VICTIMS=`ps -axo user:32,args | grep /sbin/upstart | grep -v "grep\|root\|$ADMIN" | cut -f 1 -d ' '` # By extracting users who started a grafical session (users logged on with 'ssh -X' will NOT be detected)

echo List of victims: $VICTIMS

for VICTIM in $VICTIMS; do
	echo "Starting victim $VICTIM ..."
	# Shortcuts to configuration files.
	ROLLOVER_DATE_FILE=/root/$VICTIM-rollover-date.cfg
	TIME_LEFT_FILE=/root/$VICTIM-time-left.cfg
	TIME_LEFT_FILE_FOR_USER=/tmp/$VICTIM-time-left.cfg

	# STEP ONE
	# The entire script relies on the fact that a user must be logged in.
	# Any user -- root, the admininstrator, user1, user2, etc. If nobody
	# is logged in, the script has nothing to do. So, exit.

	# combined with...

	# STEP TWO
	# The administrator has unlimited access (consequently, so does root),
	# thus the script doesn't need to run if admin/root is logged in.

	# STEP THREE
	# Check if $VICTIM already have the two configuration files in root's
	# directory. If neither one nor both are present, it is assumed that
	# $VICTIM is a new user account, so create them on the fly.  Otherwise
	# read the files and store the values to variables.

	if [ ! -e "$ROLLOVER_DATE_FILE" -o ! -e "$TIME_LEFT_FILE" ]
	then
		echo $YESTERDAY > $ROLLOVER_DATE_FILE
		echo $TIME_LEFT > $TIME_LEFT_FILE
		echo $TIME_LEFT > $TIME_LEFT_FILE_FOR_USER
	else
		YESTERDAY=`cat $ROLLOVER_DATE_FILE`
		TIME_LEFT=`cat $TIME_LEFT_FILE`
	fi

	# STEP FOUR
	# No longer necessary since it's been superseded by
	# the else statement in STEP THREE

	# STEP FIVE
	# If $TODAY and $YESTERDAY do not match, either a new day already has begun
	# or STEP THREE happened. If this is the case, re-set the configuration files.

	if [ "$TODAY" != "$YESTERDAY" ]
	then
		# Find out the allocated time for $VICTIM.  If $VICTIM's not found
		# in the configuration file, defaults to zero.
		TIME_LEFT=`grep $VICTIM $USERS_AND_TIMES_FILE | awk '{print $2}'`
		if [ -z $TIME_LEFT ]
		then
			# Default time left if not found in $USERS_AND_TIMES_FILE:
			TIME_LEFT=60
			# This may be the value used by guest sessions.
			# Users of those sessions have the form "guest-abcdef" where abcdef is a random string.
			# So that each new session has a new $TIME_LEFT as informed above.
			# You may wish to disable guest account if using this script...
		fi
		echo $TODAY > $ROLLOVER_DATE_FILE
		echo $TIME_LEFT > $TIME_LEFT_FILE 
		echo $TIME_LEFT > $TIME_LEFT_FILE_FOR_USER
	fi

	# STEP SIX
	# Remind the VICTIM that he/she has $TIME_LEFT minute(s) left for the day.

	UPSTART_PID=`ps -axo pid,user:32,args | grep /sbin/upstart | grep ^$VICTIM | grep -v grep | awk '{print $1}'`
	#Trying to get the DISPLAY from the arguments of the Window Manager:
	DISP=`ps -aux | grep wm | grep ^$VICTIM | grep -v grep | tr -s ' ' | cut -f 13 -d ' '`
	#if the upper line did not work, try an alternative method:
	if [ -z $DISP ]
	then
		DISP=`cat /proc/$UPSTART_PID/environ 2>/dev/null | tr '\0' '\n' | grep '^DISPLAY=' | cut -d "=" -f 2`
	fi

	# Display a warning message on the victim's screen:
	sudo -u $VICTIM DISPLAY=$DISP notify-send -t 10000 -i gtk-info "Reminder:" "You have $TIME_LEFT minutes left for the day." &
	#  "Reminder:" "You have $TIME_LEFT minutes left for the day."
	# for French/français:
	#  "Rappel:" "Il te reste $TIME_LEFT minutes pour aujourd hui."

	# Audio play a warning (so that if victim is in a full-screen game, he will hear the message)
	# TODO I got problem 'unable to open slave' with all of the below: aplay (package alsa-utils), speaker-test, play (package sox),...
	#aplay -N -c 31 /home/$ADMIN/ParentalControl_5mn_left.wav
	#paplay /home/$ADMIN/ParentalControl_5mn_left.wav
	#speaker-test -l 1 -t wav -r 44100 -w /home/$ADMIN/ParentalControl_5mn_left_mono.wav
	#play /home/$ADMIN/ParentalControl_5mn_left_mono.wav
	#mplayer /home/$ADMIN/ParentalControl_5mn_left_mono.wav
	#sudo -u $VICTIM DISPLAY=$DISP cvlc --play-and-exit /home/$ADMIN/ParentalControl_5mn_left_mono.wav
	#sudo -u $VICTIM DISPLAY=$DISP totem /home/$ADMIN/ParentalControl_5mn_left_mono.wav &
	if [ $TIME_LEFT -lt 6 ]
	then
		espeak -v english "Remaining $TIME_LEFT minutes left."
		#espeak -v french "Il reste $TIME_LEFT minutes."
	fi

	# STEPs SEVEN and EIGHT
	# Find out if $VICTIM exhausted the allowed time limit.  If there's still
	# $TIME_LEFT, decrease by 1 and store the new value in the configuration file.
	# Otherwise lock the screen (or force an ungraceful logout).
	if [ $TIME_LEFT -gt 0 ]
	then
		echo "Still $TIME_LEFT minutes left for user $VICTIM ."
		TIME_LEFT=`expr $TIME_LEFT - 1`
		echo $TIME_LEFT > $TIME_LEFT_FILE
		cp $TIME_LEFT_FILE $TIME_LEFT_FILE_FOR_USER
		chmod 700 $TIME_LEFT_FILE_FOR_USER
		chown $VICTIM:$VICTIM $TIME_LEFT_FILE_FOR_USER
 	else
		echo "Time expired for user $VICTIM , we lock screen or logout."

		# The most generic way to force-close the session:
		sudo -u $VICTIM kill -15 $UPSTART_PID

		# Killing the session:
		# Works with Xfce4, replace 'xfce4-session' with approppriate one to adapt for the others:
		# sudo -u $VICTIM DISPLAY=$DISP kill `ps -ef | grep xfce4-session | grep -v grep | grep ^$VICTIM | tr -s ' ' | cut -f 2 -d ' '`  
		# sudo -u $VICTIM DISPLAY=$DISP gnome-screensaver-command --activate --lock		# If using gnome

		# The command below will force an ungraceful logout -- not recommended!
		# passwd -l $VICTIM
		# sudo pkill -u $VICTIM

		# Display logout screen:
		# sudo -u $VICTIM DISPLAY=$DISP xfce4-session-logout --logout # Return a D-Bus error: "Failed to connect to socket"
	fi
	echo "We're done for user $VICTIM !"
done
echo "We're done for ALL users !"
exit 0

