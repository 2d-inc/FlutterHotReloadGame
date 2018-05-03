#!/bin/sh
# Renice
pgrep -f "Monitor Shell" | xargs sudo renice -n -20
# Print out to check if the process was niced successfully
pgrep -f "Monitor Shell" | xargs ps -o ni
