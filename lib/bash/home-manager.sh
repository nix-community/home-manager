#!/usr/bin/env bash

#
# This file contains a number of utilities for use by the home-manager tool and
# the generated Home Manager activation scripts. No guarantee is made about
# backwards or forward compatibility.
#

# Sets up colors suitable for the `errorEcho`, `warnEcho`, and `noteEcho`
# functions.
#
# The check for terminal output and color support is heavily inspired by
# https://unix.stackexchange.com/a/10065.
#
# The setup respects the `NO_COLOR` environment variable.
function setupColors() {
    normalColor=""
    errorColor=""
    warnColor=""
    noteColor=""

    # Enable colors for terminals, and allow opting out.
    if [[ ! -v NO_COLOR && -t 1 ]]; then
        # See if it supports colors.
        local ncolors
        ncolors=$(tput colors)

        if [[ -n "$ncolors" && "$ncolors" -ge 8 ]]; then
            normalColor="$(tput sgr0)"
            errorColor="$(tput bold)$(tput setaf 1)"
            warnColor="$(tput setaf 3)"
            noteColor="$(tput bold)$(tput setaf 6)"
        fi
    fi
}

setupColors

function errorEcho() {
    echo "${errorColor}$*${normalColor}"
}

function warnEcho() {
    echo "${warnColor}$*${normalColor}"
}

function noteEcho() {
    echo "${noteColor}$*${normalColor}"
}

function _i() {
    local msgid="$1"
    shift

    # shellcheck disable=2059
    printf "$(gettext "$msgid")\n" "$@"
}

function _ip() {
    local msgid="$1"
    local msgidPlural="$2"
    local count="$3"
    shift 3

    # shellcheck disable=2059
    printf "$(ngettext "$msgid" "$msgidPlural" "$count")\n" "$@"
}

function _iError() {
    echo -n "${errorColor}"
    _i "$@"
    echo -n "${normalColor}"
}

function _iWarn() {
    echo -n "${warnColor}"
    _i "$@"
    echo -n "${normalColor}"
}

function _iNote() {
    echo -n "${noteColor}"
    _i "$@"
    echo -n "${normalColor}"
}
