# shellcheck shell=sh
# Ctrl-S ne fige plus le terminal.

if [ -t 0 ]; then stty -ixon 2>/dev/null; fi
