function setupColors() {
    normalColor=""
    errorColor=""
    warnColor=""
    noteColor=""

    # Check if stdout is a terminal.
    if [[ -t 1 ]]; then
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
