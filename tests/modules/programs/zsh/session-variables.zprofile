# Environment variables
. "/nix/store/00000000000000000000000000000000-hm-session-vars.sh/etc/profile.d/hm-session-vars.sh"

# Only source this once
if [[ -z "${__HM_ZSH_SESS_VARS_SOURCED-}" ]]; then
  export __HM_ZSH_SESS_VARS_SOURCED=1
  export ALT_CONSTANT="${ALT_CONSTANT:+fixed}"
  export ALT_IDENTITY="${ALT_IDENTITY:+$ALT_IDENTITY}"
  export BRACED="${BRACED}"
  export DEFAULT="${DEFAULT:-fallback}"
  export DIRECT="$DIRECT"
  export ESCAPED="\\$ESCAPED"
  export IS_EMPTY=""
  export IS_FALSE=false
  export IS_TRUE=true
  export PATH="$HOME/bin:$PATH"
  export V1="v1"
  export V2="v2-v1"
fi
