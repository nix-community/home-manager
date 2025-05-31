# -*- mode: sh; sh-shell: bash -*-

@initHomeManagerLib@

# A symbolic link whose target path matches this pattern will be
# considered part of a Home Manager generation.
homeFilePattern="$(readlink -e @storeDir@)/*-home-manager-files/*"

newGenFiles="$1"
shift 1
for relativePath in "$@" ; do
  targetPath="$HOME/$relativePath"
  if [[ -e "$newGenFiles/$relativePath" ]] ; then
    verboseEcho "Checking $targetPath: exists"
  elif [[ ! "$(readlink "$targetPath")" == $homeFilePattern ]] ; then
    warnEcho "Path '$targetPath' does not link into a Home Manager generation. Skipping delete."
  else
    verboseEcho "Checking $targetPath: gone (deleting)"
    run rm $VERBOSE_ARG "$targetPath"

    # Recursively delete empty parent directories.
    targetDir="$(dirname "$relativePath")"
    if [[ "$targetDir" != "." ]] ; then
      pushd "$HOME" > /dev/null

      # Call rmdir with a relative path excluding $HOME.
      # Otherwise, it might try to delete $HOME and exit
      # with a permission error.
      run rmdir $VERBOSE_ARG \
          -p --ignore-fail-on-non-empty \
          "$targetDir"

      popd > /dev/null
    fi
  fi
done
