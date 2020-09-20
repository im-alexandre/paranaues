#!/usr/bin/env bash

nitrogen --restore &
while [[ true ]]; do
    bateria=`upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep percentage | awk '{ print $2}'`
    som=`awk -F"[][]" '/dB/ { print $2 }' <(amixer sget Master)`
    hora=`date +"%A-%d de %B | %T"`
    xsetroot -name "Bateria: $bateria | Volume: $som | $hora"
    sleep 0.5s
done



