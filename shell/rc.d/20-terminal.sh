# shellcheck shell=sh
# Ctrl-S et Ctrl-Q ne figent plus le terminal (contrôle de flux XON/XOFF désactivé).

if [ -t 0 ]; then stty -ixon 2>/dev/null; fi
