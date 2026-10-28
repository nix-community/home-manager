# shellcheck shell=sh
# Merge entries into a separator-delimited search variable.
#
#   __hm_merge <prepend|append> <NAME> <SEP> [ENTRY...]
#
# The first merge in a process tree removes existing occurrences before placing
# entries according to mode. Later merges keep existing positions. The exported
# `__HM_SESS_VARS_MERGED` marker distinguishes those cases independently of
# `__HM_SESS_VARS_SOURCED`.
#
# POSIX sh has no arrays or `${var//pattern/}`. Quoting the `case` and parameter
# expansion patterns keeps glob metacharacters in entries literal.
__hm_merge() {
  __hm_mode=$1
  __hm_name=$2
  __hm_sep=$3
  shift 3

  eval "__hm_cur=\${$__hm_name-}"
  __hm_add=

  if [ -z "${__HM_SESS_VARS_MERGED-}" ]; then
    __hm_reposition=1
  else
    __hm_reposition=
  fi

  for __hm_entry in "$@"; do
    # Empty path elements usually mean the current directory and cannot be
    # deduplicated reliably. Entries expand only when sourced, so filter them here.
    [ -n "$__hm_entry" ] || continue

    case "$__hm_sep$__hm_add$__hm_sep" in
      *"$__hm_sep$__hm_entry$__hm_sep"*) continue ;;
    esac

    if [ -n "$__hm_reposition" ]; then
      # Each pass removes one occurrence, so the loop terminates.
      __hm_work="$__hm_sep$__hm_cur$__hm_sep"
      while :; do
        case "$__hm_work" in
          *"$__hm_sep$__hm_entry$__hm_sep"*) ;;
          *) break ;;
        esac
        __hm_pre="${__hm_work%%"$__hm_sep$__hm_entry$__hm_sep"*}"
        __hm_post="${__hm_work#*"$__hm_sep$__hm_entry$__hm_sep"}"
        __hm_work="$__hm_pre$__hm_sep$__hm_post"
      done
      __hm_work="${__hm_work#"$__hm_sep"}"
      __hm_cur="${__hm_work%"$__hm_sep"}"
    else
      case "$__hm_sep$__hm_cur$__hm_sep" in
        *"$__hm_sep$__hm_entry$__hm_sep"*) continue ;;
      esac
    fi

    __hm_add="$__hm_add${__hm_add:+$__hm_sep}$__hm_entry"
  done

  if [ -n "$__hm_add" ]; then
    if [ "$__hm_mode" = prepend ]; then
      eval "$__hm_name=\"\$__hm_add\${__hm_cur:+\$__hm_sep}\$__hm_cur\""
    else
      eval "$__hm_name=\"\$__hm_cur\${__hm_cur:+\$__hm_sep}\$__hm_add\""
    fi
  else
    # Export the variable even when all configured entries already exist.
    eval "$__hm_name=\$__hm_cur"
  fi

  # SC2163: indirect export works in bash, dash, zsh, and BusyBox ash.
  # shellcheck disable=SC2163
  export "$__hm_name"
}
