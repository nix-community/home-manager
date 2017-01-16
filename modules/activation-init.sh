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

    newGenPath="@GENERATION_DIR@";
    newGenProfilePath="$profilesPath/home-manager-$newGenNum-link"
    newGenGcPath="$gcPath/current-home"
}

setupVars

echo "Starting home manager activation"

if [[ $DRY_RUN ]] ; then
  echo "This is a dry run"
  export DRY_RUN_CMD=echo
else
  echo "This is a live run"
  unset DRY_RUN_CMD
fi

echo "Activation variables:"
echo "  oldGenNum=$oldGenNum"
echo "  newGenNum=$newGenNum"
echo "  oldGenPath=$oldGenPath"
echo "  newGenPath=$newGenPath"
echo "  newGenProfilePath=$newGenProfilePath"
echo "  newGenGcPath=$newGenGcPath"
