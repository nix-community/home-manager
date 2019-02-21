#!/usr/bin/env bash

function setupVars() {
    local profilesPath="/nix/var/nix/profiles/per-user/$USER"
    local gcPath="/nix/var/nix/gcroots/per-user/$USER"
    local greatestGenNum

    if [[ ! -d "${profilesPath}" ]]; then
        mkdir -p "${profilesPath}"
    fi

    if [[ ! -d "${gcPath}" ]]; then
        mkdir -p "${gcPath}"
    fi

    greatestGenNum=$( \
        find "$profilesPath" -name 'home-manager-*-link' \
            | sed 's/^.*-\([0-9]*\)-link$/\1/' \
            | sort -rn \
            | head -1)

    if [[ -n $greatestGenNum ]] ; then
        oldGenNum=$greatestGenNum
    else
        oldGenNum=0
    fi
    newGenNum=$((oldGenNum + 1))

    if [[ -e $gcPath/current-home ]] ; then
        oldGenPath="$(readlink -e "$gcPath/current-home")"
    fi

    genProfilePath="$profilesPath/home-manager"
    newGenPath="@GENERATION_DIR@";
    newGenProfilePath="$profilesPath/home-manager-$newGenNum-link"
    newGenGcPath="$gcPath/current-home"
}

if [[ -v VERBOSE ]]; then
    export VERBOSE_ECHO=echo
    export VERBOSE_ARG="--verbose"
else
    export VERBOSE_ECHO=true
    export VERBOSE_ARG=""
fi

echo "Starting home manager activation"

setupVars

if [[ -v DRY_RUN ]] ; then
    echo "This is a dry run"
    export DRY_RUN_CMD=echo
else
    $VERBOSE_ECHO "This is a live run"
    export DRY_RUN_CMD=""
fi

if [[ -v VERBOSE ]]; then
    echo -n "Using Nix version: "
    nix-env --version
fi

$VERBOSE_ECHO "Activation variables:"
if [[ -v oldGenNum ]] && [[ "${oldGenNum}" -gt 0 ]] ; then
    $VERBOSE_ECHO "  oldGenNum=$oldGenNum"
    $VERBOSE_ECHO "  oldGenPath=$oldGenPath"
else
    $VERBOSE_ECHO "  oldGenNum undefined (first run?)"
    $VERBOSE_ECHO "  oldGenPath undefined (first run?)"
fi
$VERBOSE_ECHO "  newGenPath=$newGenPath"
$VERBOSE_ECHO "  newGenNum=$newGenNum"
$VERBOSE_ECHO "  newGenProfilePath=$newGenProfilePath"
$VERBOSE_ECHO "  newGenGcPath=$newGenGcPath"
$VERBOSE_ECHO "  genProfilePath=$genProfilePath"
