#!/usr/bin/env bash

function isStartable() {
  local service="$1"
  [[ $(systemctl --user show -p RefuseManualStart "$service") == *=no ]]
}

function isStoppable() {
  if [[ -v oldGenPath ]] ; then
    local service="$1"
    [[ $(systemctl --user show -p RefuseManualStop "$service") == *=no ]]
  fi
}

function systemdPostReload() {
  local workDir
  workDir="$(mktemp -d)"

  if [[ -v oldGenPath ]] ; then
    local oldUserServicePath="$oldGenPath/home-files/.config/systemd/user"
  fi

  local newUserServicePath="$newGenPath/home-files/.config/systemd/user"
  local oldServiceFiles="$workDir/old-files"
  local newServiceFiles="$workDir/new-files"
  local servicesDiffFile="$workDir/diff-files"

  if [[ ! (-v oldUserServicePath && -d "$oldUserServicePath") \
      && ! -d "$newUserServicePath" ]]; then
    return
  fi

  if [[ ! (-v oldUserServicePath && -d "$oldUserServicePath") ]]; then
    touch "$oldServiceFiles"
  else
    find "$oldUserServicePath" \
      -maxdepth 1 -name '*.service' -exec basename '{}' ';' \
      | sort \
      > "$oldServiceFiles"
  fi

  if [[ ! -d "$newUserServicePath" ]]; then
    touch "$newServiceFiles"
  else
    find "$newUserServicePath" \
      -maxdepth 1 -name '*.service' -exec basename '{}' ';' \
      | sort \
      > "$newServiceFiles"
  fi

  diff \
    --new-line-format='+%L' \
    --old-line-format='-%L' \
    --unchanged-line-format=' %L' \
    "$oldServiceFiles" "$newServiceFiles" \
    > "$servicesDiffFile" || true

  local -a maybeRestart=( $(grep '^ ' "$servicesDiffFile" | cut -c2-) )
  local -a maybeStop=( $(grep '^-' "$servicesDiffFile" | cut -c2-) )
  local -a maybeStart=( $(grep '^+' "$servicesDiffFile" | cut -c2-) )
  local -a toRestart=( )
  local -a toStop=( )
  local -a toStart=( )

  for f in "${maybeRestart[@]}" ; do
    if isStoppable "$f" \
        && isStartable "$f" \
        && systemctl --quiet --user is-active "$f" \
        && ! cmp --quiet \
            "$oldUserServicePath/$f" \
            "$newUserServicePath/$f" ; then
      toRestart+=("$f")
    fi
  done

  for f in "${maybeStop[@]}" ; do
    if isStoppable "$f" ; then
      toStop+=("$f")
    fi
  done

  for f in "${maybeStart[@]}" ; do
    if isStartable "$f" ; then
      toStart+=("$f")
    fi
  done

  rm -r "$workDir"

  local sugg=""

  if [[ -n "${toRestart[@]}" ]] ; then
    sugg="${sugg}systemctl --user restart ${toRestart[@]}\n"
  fi

  if [[ -n "${toStop[@]}" ]] ; then
    sugg="${sugg}systemctl --user stop ${toStop[@]}\n"
  fi

  if [[ -n "${toStart[@]}" ]] ; then
    sugg="${sugg}systemctl --user start ${toStart[@]}\n"
  fi

  if [[ -n "$sugg" ]] ; then
    echo "Suggested commands:"
    echo -n -e "$sugg"
  fi
}

oldGenPath="$1"
newGenPath="$2"

$DRY_RUN_CMD systemctl --user daemon-reload
systemdPostReload
