#!/bin/bash
#/home/thomas/Applications/ParentalControl/display_time_left_once.sh
VICTIM=loic
#TIME_LEFT_FILE=/root/$VICTIM-time-left.cfg
TIME_LEFT_FILE_FOR_USER=/tmp/$VICTIM-time-left.cfg
TIME_LEFT=`cat $TIME_LEFT_FILE_FOR_USER`

notify-send -i gtk-info "Temps restant:" "$TIME_LEFT minutes\n pour aujourd hui."
# -t 10000

