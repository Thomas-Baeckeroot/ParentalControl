#!/bin/bash

#####
#
# Project       : Poor man's parental control
#                 Limiting a user's daily computer usage time
# Started       : May 12, 2011
# Last Modified : March, 2015
# Author        : Anthony David (Pilosopong Tasyo)
# Author (minor): Trapovid (anonymous but reachable at http://forums.linuxmint.com )
# Module        : limit-usage-time.sh
# Description   : Monitors the amount of time a user spends on the computer.
#                 Lock the screen when the limit has been reached.  Run this
#                 script as a cron job (executed once per minute).
#
# Installation explained at http://forums.linuxmint.com/viewtopic.php?f=213&t=77687
#
# Note from Trapovid:
# Original script was not working fully on my PC, so I modified it.
# I aim to be as generic as possible but I am not sure what is specific to my configuration and what is not.
# This script worked fine with Linux Mint 17.1 Xfce (with a configuration that uses more than one X terminal).
#
##########

# For debuging...
touch /tmp/limit-usage-time=running
set -x

# Some useful variables
ADMIN=thomas  # ADMIN = login name of the computer's administrator.

# Date- and time-keeping variables.
TODAY=`date +%D`
YESTERDAY=0
TIME_LEFT=0

# Shortcuts to configuration files.
USERS_AND_TIMES_FILE=/home/$ADMIN/users_and_times.cfg

# Who's currently logged in:
#VICTIMS=`users`        #This does not work if other users are connected with 'ssh' for example, also an issue if user launch various terminals...
#VICTIMS=`ps -aux | grep xinitrc | grep -v 'grep\|root\|$ADMIN' | cut -f 1 -d ' '` # By extracting user with X session
VICTIMS=`ps -aux | grep wm | grep -v "grep\|root\|$ADMIN" | cut -f 1 -d ' '` # By extracting users who started a Window Manager

# For debuging...
echo Victims are: $VICTIMS

for VICTIM in $VICTIMS; do

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

	# Eliminated by the 'grep -v "grep\|root\|$ADMIN"' so it is not needed anymore
	#if [ -z "$VICTIM" -o "$VICTIM" == "$ADMIN" -o "$VICTIM" == "root" ]
	#then
	#  break
	#fi

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
	    TIME_LEFT=0
	  fi

	  echo $TODAY > $ROLLOVER_DATE_FILE
	  echo $TIME_LEFT > $TIME_LEFT_FILE 
          echo $TIME_LEFT > $TIME_LEFT_FILE_FOR_USER
	fi

	# STEP SIX
	# Remind the VICTIM that he/she has $TIME_LEFT minute(s) left for the day.

	DISP=`ps -aux | grep wm | grep ^$VICTIM | grep -v grep | tr -s ' ' | cut -f 13 -d ' '`

	sudo -u $VICTIM DISPLAY=$DISP notify-send -t 10000 -i gtk-info "Rappel:" "Il te reste $TIME_LEFT minutes pour aujourd hui."
	#  "Reminder:" "You have $TIME_LEFT minute(s) left for the day."

	sleep 10  # It takes 10 seconds for notify-send to finish the OSD

	# STEPs SEVEN and EIGHT
	# Find out if $VICTIM exhausted the allowed time limit.  If there's still
	# $TIME_LEFT, decrease by 1 and store the new value in the configuration file.
	# Otherwise lock the screen (or force an ungraceful logout).

	if [ $TIME_LEFT -gt 0 ]
	then
	  TIME_LEFT=`expr $TIME_LEFT - 1`
	  echo $TIME_LEFT > $TIME_LEFT_FILE
          echo $TIME_LEFT > $TIME_LEFT_FILE_FOR_USER
 	else
	  # Works with Xfce4, replace 'xfce4-session' with approppriate one to adapt for the others:
	  # sudo -u $VICTIM DISPLAY=$DISP xfce4-session-logout --logout # Return a D-Bus error: "Failed to connect to socket"
	  sudo -u $VICTIM DISPLAY=$DISP kill `ps -ef | grep xfce4-session | grep -v grep | grep ^$VICTIM | tr -s ' ' | cut -f 2 -d ' '`  
	  # sudo -u $VICTIM DISPLAY=$DISP gnome-screensaver-command --activate --lock	  # If using gnome

	  # The command below will force an ungraceful logout -- not recommended!
	  # passwd -l $VICTIM
	  # sudo pkill -u $VICTIM
	fi

	# We're done for this victim!
done

# We're done for all victims!

# EOF
