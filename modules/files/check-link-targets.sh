# -*- mode: sh; sh-shell: bash -*-

@initHomeManagerLib@

# A symbolic link whose target path matches this pattern will be
# considered part of a Home Manager generation.
homeFilePattern="$(readlink -e @storeDir@)/*-home-manager-files/*"

forcedPaths=(@forcedPaths@)

newGenFiles="$1"
shift
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
  elif [[ -e "$targetPath" \
      && ! "$(readlink "$targetPath")" == $homeFilePattern ]] ; then
    # The target file already exists and it isn't a symlink owned by Home Manager.
    if cmp -s "$sourcePath" "$targetPath"; then
      # First compare the files' content. If they're equal, we're fine.
      warnEcho "Existing file '$targetPath' is in the way of '$sourcePath', will be skipped since they are the same"
    elif [[ ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_COMMAND" ]] ; then
      # Next, try to run the custom backup command. Assume this always succeeds.
      verboseEcho "Existing file '$targetPath' exists and differs from '$sourcePath'. `$HOME_MANAGER_BACKUP_COMMAND` will be used to backup the file."
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
  fi
done

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
