# The check for terminal output and color support is heavily inspired
# by https://unix.stackexchange.com/a/10065.
#
# Allow opt out by respecting the `NO_COLOR` environment variable.

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
