# Apply one generated version per process tree. The token changes when
# either the generic or Zsh-specific variables change.
if [[ "${__HM_ZSH_SESS_VARS_SOURCED-}" != "/nix/store/00000000000000000000000000000000-hm-session-vars.sh:2aa49d79310bce950e24944ffad9ea8f9a09cabb4231227a7ea196f33298224c" ]]; then
  export __HM_ZSH_SESS_VARS_SOURCED="/nix/store/00000000000000000000000000000000-hm-session-vars.sh:2aa49d79310bce950e24944ffad9ea8f9a09cabb4231227a7ea196f33298224c"
  . "/nix/store/00000000000000000000000000000000-hm-session-vars.sh/etc/profile.d/hm-session-vars.sh"
  export ALT_CONSTANT="${ALT_CONSTANT:+fixed}"
  export ALT_IDENTITY="${ALT_IDENTITY:+$ALT_IDENTITY}"
  export BRACED="${BRACED}"
  export COLLIDE="zsh"
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
