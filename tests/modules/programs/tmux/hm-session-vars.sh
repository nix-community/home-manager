# Only source this once.
if [ -n "$__HM_SESS_VARS_SOURCED" ]; then return; fi
export __HM_SESS_VARS_SOURCED=1

export TMUX_TMPDIR="${XDG_RUNTIME_DIR:-"/run/user/\$(id -u)"}"
