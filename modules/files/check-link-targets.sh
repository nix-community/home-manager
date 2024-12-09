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
    elif [[ ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_EXT" ]] ; then
      # Next, try to move the file to a backup location if configured and possible
      backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
      if [[ -e "$backup" ]]; then
        errorEcho "Existing file '$backup' would be clobbered by backing up '$targetPath'"
        collision=1
      else
        warnEcho "Existing file '$targetPath' is in the way of '$sourcePath', will be moved to '$backup'"
      fi
    else
      # Fail if nothing else works
      errorEcho "Existing file '$targetPath' is in the way of '$sourcePath'"
      collision=1
    fi
  fi
done

if [[ -v collision ]] ; then
  errorEcho "Please do one of the following:
- Move or remove the above files and try again.
- In standalone mode, use 'home-manager switch -b backup' to back up
  files automatically.
- When used as a NixOS or nix-darwin module, set
    'home-manager.backupFileExtension'
  to, for example, 'backup' and rebuild."
  exit 1
fi
