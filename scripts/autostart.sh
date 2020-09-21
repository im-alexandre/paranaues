#!/usr/bin/env bash

xcompmgr &
nitrogen --restore &
while [[ true ]]; do
    bateria=`upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep percentage | awk '{ print $2}'`
    som=`awk -F"[][]" '/dB/ { print $2 }' <(amixer sget Master)`
    hora=`date +"%A-%d%b | %T"`
    if [[ ! -z $bateria ]]; then
        xsetroot -name "  🔋 $bateria | 🔊 $som | $hora  "
    else
        xsetroot -name "  🔊 $som | $hora  "
    fi
    sleep 5s
done



