#!/bin/bash
# Gracefully cancel a running Ralph loop.
# Ralph will finish its current iteration, then stop.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
touch "$SCRIPT_DIR/.ralph-cancel"
echo "Cancel signal sent. Ralph will stop after the current iteration finishes."
