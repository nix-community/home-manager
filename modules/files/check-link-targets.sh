# -*- mode: sh; sh-shell: bash -*-

@initHomeManagerLib@

# A symbolic link whose target path matches this pattern will be
# considered part of a Home Manager generation.
homeFilePattern="$(readlink -e @storeDir@)/*-home-manager-files/*"

forcedPaths=(@forcedPaths@)

newGenFiles="$1"
shift

# Check a target that already exists and is not a symlink owned by Home
# Manager.
function checkCollision() {
  local sourcePath="$1"
  local targetPath="$2"

  if cmp -s "$sourcePath" "$targetPath"; then
    # First compare the files' content. If they're equal, we're fine.
    warnEcho "Existing file '$targetPath' is in the way of '$sourcePath', will be skipped since they are the same"
  elif [[ ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_COMMAND" ]] ; then
    # Next, try to run the custom backup command. Assume this always succeeds.
    verboseEcho "Existing file '$targetPath' exists and differs from '$sourcePath'. '$HOME_MANAGER_BACKUP_COMMAND' will be used to backup the file."
  elif [[ ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_EXT" ]] ; then
    # Next, try to move the file to a backup location if configured and possible
    backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
    if [[ -e "$backup" && -z "$HOME_MANAGER_BACKUP_OVERWRITE" ]] ; then
      collisionErrors+=("Existing file '$backup' would be clobbered by backing up '$targetPath'")
    elif [[ -e "$backup" && -n "$HOME_MANAGER_BACKUP_OVERWRITE" ]] ; then
      warnEcho "Existing file '$targetPath' is in the way of '$sourcePath' and '$backup' exists. Backup will be clobbered due to HOME_MANAGER_BACKUP_OVERWRITE=1"
    else
      warnEcho "Existing file '$targetPath' is in the way of '$sourcePath', will be moved to '$backup'"
    fi
  else
    # Fail if nothing else works
    collisionErrors+=("Existing file '$targetPath' would be clobbered")
  fi
}

# Classify every target using bash builtins only: even one forked process
# per file costs several milliseconds on some platforms (notably darwin),
# which dominates activation time when a profile carries hundreds of links.
declare -a linkTargets=() linkSources=()
for sourcePath in "$@" ; do
  relativePath="${sourcePath#$newGenFiles/}"
  targetPath="$HOME/$relativePath"

  forced=""
  for forcedPath in "${forcedPaths[@]}"; do
    if [[ $targetPath == $forcedPath* ]]; then
      forced="yeah"
      break
    fi
  done

  if [[ -n $forced ]]; then
    verboseEcho "Skipping collision check for $targetPath"
  elif [[ -L "$targetPath" && -e "$targetPath" ]] ; then
    linkTargets+=("$targetPath")
    linkSources+=("$sourcePath")
  elif [[ -e "$targetPath" ]] ; then
    checkCollision "$sourcePath" "$targetPath"
  fi
done

# Resolve all existing symlinks with a single readlink call. A link into a
# Home Manager generation is ours; anything else is a collision candidate.
if [[ ${#linkTargets[@]} -gt 0 ]] ; then
  i=0
  while IFS= read -r -d "" currentSource ; do
    if [[ ! "$currentSource" == $homeFilePattern ]] ; then
      checkCollision "${linkSources[i]}" "${linkTargets[i]}"
    fi
    i=$(( i + 1 ))
  done < <(readlink -z -- "${linkTargets[@]}")

  # readlink prints no record for an operand that vanished since the
  # classification loop above, and its exit status is lost through the
  # process substitution. A missing record shifts every later result onto
  # the wrong source, so a foreign symlink could be checked against the
  # wrong target and pass as ours. The record count is the only signal
  # that happened.
  if [[ $i -ne ${#linkTargets[@]} ]] ; then
    errorEcho "A link target changed while resolving symlinks; retry activation."
    exit 1
  fi
fi

if [[ ${#collisionErrors[@]} -gt 0 ]] ; then
  errorEcho "Please do one of the following:
- In standalone mode, use 'home-manager switch -b backup' to back up"\
" files automatically.
- When used as a NixOS or nix-darwin module, set either
  - 'home-manager.backupFileExtension', or
  - 'home-manager.backupCommand',
  to move the file to a new location in the same directory, or run a"\
" custom command.
- Set 'force = true' on the related file options to forcefully overwrite"\
" the files below. eg. 'xdg.configFile.\"mimeapps.list\".force = true'"

  for error in "${collisionErrors[@]}" ; do
    errorEcho "$error"
  done
  exit 1
fi
