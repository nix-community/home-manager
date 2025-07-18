# -*- mode: sh; sh-shell: bash -*-

@initHomeManagerLib@

# A symbolic link whose target path matches this pattern will be
# considered part of a Home Manager generation.
homeFilePattern="$(readlink -e @storeDir@)/*-home-manager-files/*"

forcedPaths=(@forcedPaths@)
copiedPaths=(@copiedPaths@)

newGenFiles="$1"
oldGenFiles="$2"
shift 2
for sourcePath in "$@" ; do
  relativePath="${sourcePath#$newGenFiles/}"
  targetPath="$HOME/$relativePath"
  oldSourcePath="$oldGenFiles/$relativePath"

  forced=""
  for forcedPath in "${forcedPaths[@]}"; do
    if [[ $targetPath == $forcedPath* ]]; then
      forced="yeah"
      break
    fi
  done

  copied=""
  for copiedPath in "${copiedPaths[@]}"; do
    if [[ $targetPath == $copiedPath* ]]; then
      copied="yeah"
      break
    fi
  done

  if [[ -n $forced ]]; then
    verboseEcho "Skipping collision check for $targetPath"
  elif [[ -e "$targetPath" \
      && ! "$(readlink "$targetPath")" == $homeFilePattern ]] ; then
    # The target file already exists and it isn't a symlink owned by Home Manager.
    if cmp -s "$sourcePath" "$targetPath"; then
      # First compare the files' content. If they're equal, we're fine.
      [[ -z $copied ]] && warnEcho "Existing file '$targetPath' is in the way of '$sourcePath', will be skipped since they are the same"
    elif [[ -n $copied && ( ! -e "$oldSourcePath" || $(cmp -s "$oldSourcePath" "$targetPath") ) ]] ; then
      # If copied, compare the files' content with the old generation. If it's
      # the same, there were no modifications, and we'll clobber it.
      :
    elif [[ ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_EXT" ]] ; then
      # Next, try to move the file to a backup location if configured and possible
      backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
      if [[ -e "$backup" ]]; then
        collisionErrors+=("Existing file '$backup' would be clobbered by backing up '$targetPath'")
      elif [[ -z $copied ]]; then
        warnEcho "Existing file '$targetPath' is in the way of '$sourcePath', will be moved to '$backup'"
      else
        warnEcho "Existing file '$targetPath' has been modified, it will be moved to '$backup'"
      fi
    else
      # Fail if nothing else works
      collisionErrors+=("Existing file '$targetPath' would be clobbered")
    fi
  fi
done

if [[ ${#collisionErrors[@]} -gt 0 ]] ; then
  errorEcho "Please do one of the following:
- Move or remove the files below and try again.
- In standalone mode, use 'home-manager switch -b backup' to back up
  files automatically.
- When used as a NixOS or nix-darwin module, set
    'home-manager.backupFileExtension'
  to, for example, 'backup' and rebuild."
  for error in "${collisionErrors[@]}" ; do
    errorEcho "$error"
  done
  exit 1
fi
