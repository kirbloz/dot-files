#!/usr/bin/env bash

TEMP="$(cat /sys/class/hwmon/hwmon3/temp1_input | awk '{sub(/000$/, "°C", $0); print}')"
echo "${TEMP:-null}"
