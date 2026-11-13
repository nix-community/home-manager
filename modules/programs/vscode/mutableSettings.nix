{
  lib,
  pkgs,
  name,
}:
let
  json5 = pkgs.python3Packages.toPythonApplication pkgs.python3Packages.json5;
in
''
  vscodeMutableSettings() (
    display_path="$1"
    settings_path="$display_path"
    settings_was_symlink=
    if [[ -L "$display_path" ]]; then
      settings_was_symlink=1
      if ! settings_path="$(${lib.getExe' pkgs.coreutils "readlink"} -e -- "$display_path")"; then
        errorEcho "Cannot resolve ${name} settings at '$display_path'; leaving the symlink unchanged."
        exit 1
      fi
    fi
    settings_directory="$(dirname "$settings_path")"
    target_existed=
    if [[ -e "$settings_path" ]]; then
      target_existed=1
    fi

    snapshot_path=
    candidate_path=
    trap '
      [[ -z "$snapshot_path" ]] || rm -f -- "$snapshot_path"
      [[ -z "$candidate_path" ]] || rm -f -- "$candidate_path"
    ' EXIT

    dynamic='{}'
    if [[ -n "$target_existed" ]]; then
      if [[ -v DRY_RUN ]]; then
        input_path="$settings_path"
      else
        if ! snapshot_path="$(mktemp "$settings_path.snapshot.XXXXXX")"; then
          errorEcho "Creating a snapshot for ${name} settings at '$display_path' failed."
          exit 1
        fi
        if ! cp --preserve=mode -- "$settings_path" "$snapshot_path"; then
          errorEcho "Snapshotting ${name} settings at '$display_path' failed."
          exit 1
        fi
        input_path="$snapshot_path"
      fi

      if dynamic="$(${lib.getExe json5} --as-json "$input_path" 2>/dev/null)"; then
        :
      elif ${lib.getExe pkgs.gnugrep} -q '[^[:space:]]' "$input_path"; then
        errorEcho "Cannot parse ${name} settings at '$display_path' as JSON5; leaving the file unchanged."
        exit 1
      else
        grep_status=$?
        if (( grep_status > 1 )); then
          errorEcho "Cannot read ${name} settings at '$display_path'; leaving the file unchanged."
          exit 1
        fi
        dynamic='{}'
      fi
    fi

    if ! static="$(${lib.getExe json5} --as-json "$2")"; then
      errorEcho "Cannot parse the declared ${name} settings for '$display_path' as JSON5."
      exit 1
    fi
    if ! settings="$(${lib.getExe pkgs.jq} -n '$dynamic * $static' --argjson dynamic "$dynamic" --argjson static "$static")"; then
      errorEcho "Merging ${name} settings for '$display_path' failed."
      exit 1
    fi

    verboseEcho "Merging declared ${name} settings into '$display_path'"
    if ! run mkdir -p "$settings_directory"; then
      errorEcho "Creating the directory '$settings_directory' failed."
      exit 1
    fi
    if [[ -v DRY_RUN ]]; then
      echo "Would update ${name} settings at '$display_path'"
      exit 0
    fi

    if ! candidate_path="$(mktemp "$settings_path.candidate.XXXXXX")"; then
      errorEcho "Creating a candidate for ${name} settings at '$display_path' failed."
      exit 1
    fi

    if ! printf '%s\n' "$settings" > "$candidate_path"; then
      errorEcho "Writing merged ${name} settings for '$display_path' failed."
      exit 1
    fi
    if [[ -n "$target_existed" ]] && ! chmod --reference="$snapshot_path" -- "$candidate_path"; then
      errorEcho "Copying permissions from '$display_path' failed."
      exit 1
    fi

    conflict=
    if [[ -n "$target_existed" ]]; then
      if [[ -n "$settings_was_symlink" ]]; then
        current_settings_path=
        if [[ ! -L "$display_path" ]] \
          || ! current_settings_path="$(${lib.getExe' pkgs.coreutils "readlink"} -e -- "$display_path")" \
          || [[ "$current_settings_path" != "$settings_path" ]]; then
          conflict=1
        fi
      elif [[ -L "$display_path" ]]; then
        conflict=1
      fi

      if ! cmp -s -- "$snapshot_path" "$settings_path"; then
        conflict=1
      fi
    elif [[ -e "$display_path" || -L "$display_path" ]]; then
      conflict=1
    fi

    if [[ -n "$conflict" ]]; then
      errorEcho "${name} settings at '$display_path' changed during activation; keeping the newer file."
      exit 1
    fi

    if ! mv -f -- "$candidate_path" "$settings_path"; then
      errorEcho "Replacing ${name} settings at '$display_path' failed."
      exit 1
    fi
    candidate_path=
  )
''
