# -*- mode: sh; sh-shell: bash -*-

@initHomeManagerLib@

@modes@

function getMode() {
  local path="$1"
  local mode="${modes["$path"]}"

  if [[ -n $mode && $mode != symlink ]]; then
    echo "$mode"
  fi
}

function isCopiedSubPath() {
  local path="$1"

  for modePath in "${!modes[@]}"; do
    if [[ $path == "$modePath" ]]; then
      return 1
    fi
  done

  for modePath in "${!modes[@]}"; do
    if [[ $path == "$modePath"* ]]; then
      local mode
      mode="$(getMode "$modePath")"

      if [[ -z $mode ]]; then
        return 1
      else
        return 0
      fi
    fi
  done

  errorEcho "'$path' does not mach a modePath nor is it a subpath of any modePath"
  exit 1
}

newGenFiles="$1"
oldGenFiles="$2"
shift 2
for sourcePath in "$@" ; do
  relativePath="${sourcePath#$newGenFiles/}"
  targetPath="$HOME/$relativePath"
  oldSourcePath="$oldGenFiles/$relativePath"
  mode="$(getMode "$relativePath")"

  if isCopiedSubPath "$relativePath"; then
    continue
  fi

  # The target exists, and
  if [[ -e "$targetPath" && ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_EXT" &&
        # should not be copied, or
        (-z $mode ||
           # is not identical to source, and
           (! $(cmp -s "$sourcePath" "$targetPath") &&
             # there's no old version, or
             (! -e "$oldSourcePath" ||
              # it's not equal to the old version either
              ! $(cmp -s "$oldSourcePath" "$targetPath")))) ]] ; then
    # back it up
    backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
    run mv $VERBOSE_ARG "$targetPath" "$backup" || errorEcho "Backup: Moving '$targetPath' failed!"
  fi

  if [[ -e "$targetPath" && ! -L "$targetPath" ]] && cmp -s "$sourcePath" "$targetPath"; then
    # The target exists but is identical – don't do anything.
    verboseEcho "Skipping '$targetPath' as it is identical to '$sourcePath'"
  elif [[ -z $mode ]]; then
    # Place that symlink, --force
    # This can still fail if the target is a directory, in which case we bail out.
    run mkdir -p $VERBOSE_ARG "$(dirname "$targetPath")"
    run ln -Tsf $VERBOSE_ARG "$sourcePath" "$targetPath" || exit 1
  else
    # Copy that file, --force
    # This can still fail if the target is a directory, in which case we bail out.
    run mkdir -p $VERBOSE_ARG "$(dirname "$targetPath")"
    run cp -TLf $VERBOSE_ARG "$sourcePath" "$targetPath" || exit 1
    run chmod $VERBOSE_ARG $mode "$targetPath"
  fi
done
