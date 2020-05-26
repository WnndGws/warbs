#!/bin/env bash

# Import configuration
while read -r LINE; do declare "$LINE"; done < warbs.conf 2> /dev/null

echo "$DRIVE2"
printf /usr/share/zoneinfo/$TIMEZONE
