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

# Set shell options
set_opts=(
  HIST_FCNTL_LOCK NO_APPEND_HISTORY NO_EXTENDED_HISTORY
  NO_HIST_EXPIRE_DUPS_FIRST NO_HIST_FIND_NO_DUPS NO_HIST_IGNORE_ALL_DUPS
  NO_HIST_IGNORE_DUPS NO_HIST_IGNORE_SPACE NO_HIST_SAVE_NO_DUPS NO_SHARE_HISTORY
  AUTO_LIST AUTO_PARAM_SLASH AUTO_PUSHD ALWAYS_TO_END CORRECT HIST_FCNTL_LOCK
  HIST_VERIFY INTERACTIVE_COMMENTS MENU_COMPLETE PUSHD_IGNORE_DUPS PUSHD_TO_HOME
  PUSHD_SILENT NOTIFY PROMPT_SUBST MULTIOS NOFLOWCONTROL NO_CORRECT_ALL
  NO_HIST_BEEP NO_NOMATCH
)
for opt in "${set_opts[@]}"; do
  setopt "$opt"
done
unset opt set_opts
