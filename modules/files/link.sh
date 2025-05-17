# -*- mode: sh; sh-shell: bash -*-

@initHomeManagerLib@

newGenFiles="$1"
shift
for sourcePath in "$@" ; do
  relativePath="${sourcePath#$newGenFiles/}"
  targetPath="$HOME/$relativePath"
  if [[ -e "$targetPath" && ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_EXT" ]] ; then
    # The target exists, back it up
    backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
    run mv $VERBOSE_ARG "$targetPath" "$backup" || errorEcho "Moving '$targetPath' failed!"
  fi

  if [[ -e "$targetPath" && ! -L "$targetPath" ]] && cmp -s "$sourcePath" "$targetPath" ; then
    # The target exists but is identical – don't do anything.
    verboseEcho "Skipping '$targetPath' as it is identical to '$sourcePath'"
  else
    # Place that symlink, --force
    # This can still fail if the target is a directory, in which case we bail out.
    run mkdir -p $VERBOSE_ARG "$(dirname "$targetPath")"
    run ln -Tsf $VERBOSE_ARG "$sourcePath" "$targetPath" || exit 1
  fi
done
