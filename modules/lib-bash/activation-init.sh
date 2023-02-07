function setupVars() {
    local nixStateDir="${NIX_STATE_DIR:-/nix/var/nix}"
    local profilesPath="$nixStateDir/profiles/per-user/$USER"
    local gcPath="$nixStateDir/gcroots/per-user/$USER"

    declare -gr nixProfilePath="$profilesPath/profile"
    declare -gr genProfilePath="$profilesPath/home-manager"
    declare -gr newGenPath="@GENERATION_DIR@";
    declare -gr newGenGcPath="$gcPath/current-home"

    local greatestGenNum
    greatestGenNum=$( \
        nix-env --list-generations --profile "$genProfilePath" \
            | tail -1 \
            | sed -E 's/ *([[:digit:]]+) .*/\1/')

    if [[ -n $greatestGenNum ]] ; then
        declare -gr oldGenNum=$greatestGenNum
        declare -gr newGenNum=$((oldGenNum + 1))
    else
        declare -gr newGenNum=1
    fi

    if [[ -e $profilesPath/home-manager ]] ; then
        oldGenPath="$(readlink -e "$profilesPath/home-manager")"
        declare -gr oldGenPath
    fi

    $VERBOSE_RUN _i "Sanity checking oldGenNum and oldGenPath"
    if [[ -v oldGenNum && ! -v oldGenPath
            || ! -v oldGenNum && -v oldGenPath ]]; then
        _i $'The previous generation number and path are in conflict! These\nmust be either both empty or both set but are now set to\n\n    \'%s\' and \'%s\'\n\nIf you don\'t mind losing previous profile generations then\nthe easiest solution is probably to run\n\n   rm %s/home-manager*\n   rm %s/current-home\n\nand trying home-manager switch again. Good luck!' \
           "${oldGenNum:-}" "${oldGenPath:-}" \
           "$profilesPath" "$gcPath"
        exit 1
    fi
}

if [[ -v VERBOSE ]]; then
    export VERBOSE_ECHO=echo
    export VERBOSE_ARG="--verbose"
    export VERBOSE_RUN=""
else
    export VERBOSE_ECHO=true
    export VERBOSE_ARG=""
    export VERBOSE_RUN=true
fi

_i "Starting Home Manager activation"

# Verify that we can connect to the Nix store and/or daemon. This will
# also create the necessary directories in profiles and gcroots.
$VERBOSE_RUN _i "Sanity checking Nix"
nix-build --expr '{}' --no-out-link

setupVars

if [[ -v DRY_RUN ]] ; then
    _i "This is a dry run"
    export DRY_RUN_CMD=echo
else
    $VERBOSE_RUN _i "This is a live run"
    export DRY_RUN_CMD=""
fi

if [[ -v VERBOSE ]]; then
    _i 'Using Nix version: %s' "$(nix-env --version)"
fi

$VERBOSE_RUN _i "Activation variables:"
if [[ -v oldGenNum ]] ; then
    $VERBOSE_ECHO "  oldGenNum=$oldGenNum"
    $VERBOSE_ECHO "  oldGenPath=$oldGenPath"
else
    $VERBOSE_ECHO "  oldGenNum undefined (first run?)"
    $VERBOSE_ECHO "  oldGenPath undefined (first run?)"
fi
$VERBOSE_ECHO "  newGenPath=$newGenPath"
$VERBOSE_ECHO "  newGenNum=$newGenNum"
$VERBOSE_ECHO "  newGenGcPath=$newGenGcPath"
$VERBOSE_ECHO "  genProfilePath=$genProfilePath"
