# Moves the existing profile from /nix or $XDG_STATE_HOME/home-manager to
# $XDG_STATE_HOME/nix to match changed behavior in Nix 2.14. See
# https://github.com/NixOS/nix/pull/5226.
function migrateProfile() {
    declare -r stateHome="${XDG_STATE_HOME:-$HOME/.local/state}"
    declare -r userNixStateDir="$stateHome/nix"
    declare -r hmStateDir="$stateHome/home-manager"

    declare -r globalNixStateDir="${NIX_STATE_DIR:-/nix/var/nix}"
    declare -r globalProfilesDir="$globalNixStateDir/profiles/per-user/$USER"

    if [[ -e $globalProfilesDir/home-manager ]]; then
        declare -r oldProfilesDir="$globalProfilesDir"
    elif [[ -e $hmStateDir/profiles/home-manager ]]; then
        declare -r oldProfilesDir="$hmStateDir/profiles"
    fi

    declare -r newProfilesDir="$userNixStateDir/profiles"

    if [[ -v oldProfilesDir && -e $newProfilesDir ]]; then
        if [[ ! -e $newProfilesDir/home-manager ]]; then
            _i 'Migrating profile from %s to %s' "$oldProfilesDir" "$newProfilesDir"
            for p in "$oldProfilesDir"/home-manager-*; do
                declare name="${p##*/}"
                nix-store --realise "$p" --add-root "$newProfilesDir/$name" > /dev/null
            done
            cp -P "$oldProfilesDir/home-manager" "$newProfilesDir"
        fi

        rm "$oldProfilesDir/home-manager" "$oldProfilesDir"/home-manager-*
    fi
}

function setupVars() {
    declare -r stateHome="${XDG_STATE_HOME:-$HOME/.local/state}"
    declare -r userNixStateDir="$stateHome/nix"
    declare -gr hmStatePath="$stateHome/home-manager"
    declare -r hmGcrootsDir="$hmStatePath/gcroots"

    declare -r globalNixStateDir="${NIX_STATE_DIR:-/nix/var/nix}"
    declare -r globalProfilesDir="$globalNixStateDir/profiles/per-user/$USER"
    declare -r globalGcrootsDir="$globalNixStateDir/gcroots/per-user/$USER"

    # If the user Nix profiles path exists, then place the HM profile there.
    # Otherwise, if the global Nix per-user state directory exists then use
    # that. If neither exists, then we give up.
    #
    # shellcheck disable=2174
    if [[ -d $userNixStateDir/profiles ]]; then
        declare -r profilesDir="$userNixStateDir/profiles"
    elif [[ -d $globalProfilesDir ]]; then
        declare -r profilesDir="$globalProfilesDir"
    else
        _iError 'Could not find suitable profile directory, tried %s and %s' \
                "$userNixStateDir/profiles" "$globalProfilesDir" >&2
        exit 1
    fi

    declare -gr hmDataPath="${XDG_DATA_HOME:-$HOME/.local/share}/home-manager"
    declare -gr genProfilePath="$profilesDir/home-manager"
    declare -gr newGenPath="@GENERATION_DIR@";
    declare -gr newGenGcPath="$hmGcrootsDir/new-home"
    declare -gr currentGenGcPath="$hmGcrootsDir/current-home"
    declare -gr legacyGenGcPath="$globalGcrootsDir/current-home"

    if [[ -e $currentGenGcPath ]] ; then
        declare -g oldGenPath
        oldGenPath="$(readlink -e "$currentGenGcPath")"
    fi
}

# Helper used to list content of a `nix profile` profile.
function nixProfileList() {
    # We attempt to use `--json` first (added in Nix 2.17). Otherwise attempt to
    # parse the legacy output format.
    {
        nix profile list --json 2>/dev/null \
            | jq -r --arg name "$1" '.elements[].storePaths[] | select(endswith($name))'
    } || {
        nix profile list \
            | { grep "$1\$" || test $? = 1; } \
            | cut -d ' ' -f 4
    }
}

# Helper used to remove a package from a Nix profile. Supports both `nix-env`
# and `nix profile`.
function nixProfileRemove() {
    # We don't use `cfg.profileDirectory` here because it defaults to
    # `/etc/profiles/per-user/<user>` which is constructed by NixOS or
    # nix-darwin and won't require uninstalling `home-manager-path`.
    if  [[ -e $HOME/.nix-profile/manifest.json \
        || -e ${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile/manifest.json ]] ; then
        nixProfileList "$1" | xargs -rt $DRY_RUN_CMD nix profile remove $VERBOSE_ARG
    else
        if nix-env -q | grep -q "^$1$"; then
            run --silence nix-env -e "$1"
        fi
    fi
}

function checkUsername() {
  local expectedUser="$1"

  if [[ "$USER" != "$expectedUser" ]]; then
    _iError 'Error: USER is set to "%s" but we expect "%s"' "$USER" "$expectedUser"
    exit 1
  fi
}

function checkHomeDirectory() {
  local expectedHome="$1"

  if ! [[ $HOME -ef $expectedHome ]]; then
    _iError 'Error: HOME is set to "%s" but we expect "%s"' "$HOME" "$expectedHome"
    exit 1
  fi
}

# Note, the VERBOSE_ECHO variable is deprecated and should not be used inside
# the Home Manager project. It is provided here for backwards compatibility.
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
_iVerbose "Sanity checking Nix"
nix-build --expr '{}' --no-out-link

# Also make sure that the Nix profiles path is created.
nix-env -q > /dev/null 2>&1 || true

migrateProfile
setupVars

# Note, the DRY_RUN_CMD and DRY_RUN_NULL variables are deprecated and should not
# be used inside the Home Manager project. They are provided here for backwards
# compatibility.
if [[ -v DRY_RUN ]] ; then
    _i "This is a dry run"
    export DRY_RUN_CMD=echo
    export DRY_RUN_NULL=/dev/stdout
else
    _iVerbose "This is a live run"
    export DRY_RUN_CMD=""
    export DRY_RUN_NULL=/dev/null
fi

if [[ -v VERBOSE ]]; then
    _i 'Using Nix version: %s' "$(nix-env --version)"
fi

_iVerbose "Activation variables:"
if [[ -v oldGenPath ]] ; then
    verboseEcho "  oldGenPath=$oldGenPath"
else
    verboseEcho "  oldGenPath undefined (first run?)"
fi
verboseEcho "  newGenPath=$newGenPath"
verboseEcho "  genProfilePath=$genProfilePath"
verboseEcho "  newGenGcPath=$newGenGcPath"
verboseEcho "  currentGenGcPath=$currentGenGcPath"
verboseEcho "  legacyGenGcPath=$legacyGenGcPath"
