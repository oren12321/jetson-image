#! /usr/bin/env bash
#
# Author: oren12321 <oren12321@gmail.com>
#
# Description: logging utils.
#
#/ Usage: source ./log.sh
#/


#{{{ Bash settings
set -euo pipefail
#}}}

#{{{ Helper functions

lerror() {
    printf "\e[1;31m%s\e[0m\n" "${*}" 1>&2
}

linfo() {
    printf "\e[1;32m%s\e[0m\n" "${*}"
}

lwarning() {
    printf "\e[1;33m%s\e[0m\n" "${*}"
}

#}}}

