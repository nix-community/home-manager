typeset -U path cdpath fpath manpath
for profile in ${(z)NIX_PROFILES}; do
  fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
done

HELPDIR="@zsh@/share/zsh/$ZSH_VERSION/help"

autoload -U compinit && compinit
# History options should be set in .zshrc and after oh-my-zsh sourcing.
# See https://github.com/nix-community/home-manager/issues/177.
HISTSIZE="50000"
SAVEHIST="50000"

HISTFILE="/home/hm-user/.zsh_history"
mkdir -p "$(dirname "$HISTFILE")"

setopt HIST_FCNTL_LOCK

# Disabled history options
disabled_opts=(
  APPEND_HISTORY EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS
  HIST_IGNORE_ALL_DUPS HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS
  SHARE_HISTORY
)
for opt in "${disabled_opts[@]}"; do
  unsetopt "$opt"
done
unset opt disabled_opts

# Set shell options
set_opts=(
  AUTO_LIST AUTO_PARAM_SLASH AUTO_PUSHD ALWAYS_TO_END CORRECT HIST_FCNTL_LOCK
  HIST_VERIFY INTERACTIVE_COMMENTS MENU_COMPLETE PUSHD_IGNORE_DUPS PUSHD_TO_HOME
  PUSHD_SILENT NOTIFY PROMPT_SUBST MULTIOS NOFLOWCONTROL NO_CORRECT_ALL
  NO_HIST_BEEP NO_NOMATCH
)
for opt in "${set_opts[@]}"; do
  setopt "$opt"
done
unset opt set_opts
