#!/bin/bash
#/.../ParentalControl/display_time_left_once.sh
# Basic script to be called by user to display his time left
# TODO Just the general idea here. Still to be streamlined
# TODO Install script should copy it to some place like /usr/bin/
VICTIM=loic
#TIME_LEFT_FILE=/root/$VICTIM-time-left.cfg
TIME_LEFT_FILE_FOR_USER=/tmp/$VICTIM-time-left.cfg
TIME_LEFT=`cat $TIME_LEFT_FILE_FOR_USER`

notify-send -i gtk-info "Temps restant:" "$TIME_LEFT minutes\n pour aujourd hui."
# -t 10000

