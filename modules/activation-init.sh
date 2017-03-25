function setupVars() {
    local profilesPath="/nix/var/nix/profiles/per-user/$USER"
    local gcPath="/nix/var/nix/gcroots/per-user/$USER"
    local greatestGenNum

    greatestGenNum=$( \
        find "$profilesPath" -name 'home-manager-*-link' \
            | sed 's/^.*-\([0-9]*\)-link$/\1/' \
            | sort -rn \
            | head -1)

    if [[ -n "$greatestGenNum" ]] ; then
        oldGenNum=$greatestGenNum
        newGenNum=$((oldGenNum + 1))
    else
        newGenNum=1
    fi

    if [[ -e "$gcPath/current-home" ]] ; then
        oldGenPath="$(readlink -e "$gcPath/current-home")"
    fi

    genProfilePath="$profilesPath/home-manager"
    newGenPath="@GENERATION_DIR@";
    newGenProfilePath="$profilesPath/home-manager-$newGenNum-link"
    newGenGcPath="$gcPath/current-home"
}

setupVars

echo "Starting home manager activation"

if [[ -v VERBOSE ]]; then
    export VERBOSE_ECHO=echo
    export VERBOSE_ARG="--verbose"
else
    export VERBOSE_ECHO=true
    export VERBOSE_ARG=""
fi

if [[ -v DRY_RUN ]] ; then
    $VERBOSE_ECHO "This is a dry run"
    export DRY_RUN_CMD=echo
else
    $VERBOSE_ECHO "This is a live run"
    export DRY_RUN_CMD=""
fi

$VERBOSE_ECHO "Activation variables:"
$VERBOSE_ECHO "  oldGenNum=$oldGenNum"
$VERBOSE_ECHO "  newGenNum=$newGenNum"
$VERBOSE_ECHO "  oldGenPath=$oldGenPath"
$VERBOSE_ECHO "  newGenPath=$newGenPath"
$VERBOSE_ECHO "  newGenProfilePath=$newGenProfilePath"
$VERBOSE_ECHO "  newGenGcPath=$newGenGcPath"
$VERBOSE_ECHO "  genProfilePath=$genProfilePath"
