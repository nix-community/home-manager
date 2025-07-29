# -*- mode: sh; sh-shell: bash -*-

mkdir -p $out

# Needed in case /nix is a symbolic link.
realOut="$(realpath -m "$out")"

function insertFile() {
  local source="$1"
  local relTarget="$2"
  local executable="$3"
  local recursive="$4"
  local ignorelinks="$5"

  # If the target already exists then we have a collision. Note, this
  # should not happen due to the assertion found in the 'files' module.
  # We therefore simply log the conflict and otherwise ignore it, mainly
  # to make the `files-target-config` test work as expected.
  if [[ -e "$realOut/$relTarget" ]]; then
    echo "File conflict for file '$relTarget'" >&2
    return
  fi

  # Figure out the real absolute path to the target.
  local target
  target="$(realpath -m "$realOut/$relTarget")"

  # Target path must be within $HOME.
  if [[ ! $target == $realOut* ]] ; then
    echo "Error installing file '$relTarget' outside \$HOME" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$target")"
  if [[ -d $source ]]; then
    if [[ $recursive ]]; then
      mkdir -p "$target"
      if [[ $ignorelinks ]]; then
        lndir -silent -ignorelinks "$source" "$target"
      else
        lndir -silent "$source" "$target"
      fi
    else
      ln -s "$source" "$target"
    fi
  else
    [[ -x $source ]] && isExecutable=1 || isExecutable=""

    # Link the file into the home file directory if possible,
    # i.e., if the executable bit of the source is the same we
    # expect for the target. Otherwise, we copy the file and
    # set the executable bit to the expected value.
    if [[ $executable == inherit || $isExecutable == $executable ]]; then
      ln -s "$source" "$target"
    else
      cp "$source" "$target"

      if [[ $executable == inherit ]]; then
        # Don't change file mode if it should match the source.
        :
      elif [[ $executable ]]; then
        chmod +x "$target"
      else
        chmod -x "$target"
      fi
    fi
  fi
}

source "$insertFilesPath"
