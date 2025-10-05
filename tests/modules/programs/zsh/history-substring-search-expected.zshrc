typeset -U path cdpath fpath manpath
for profile in ${(z)NIX_PROFILES}; do
  fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
done

HELPDIR="@zsh@/share/zsh/$ZSH_VERSION/help"

autoload -U compinit && compinit
# History options should be set in .zshrc and after oh-my-zsh sourcing.
# See https://github.com/nix-community/home-manager/issues/177.
HISTSIZE="10000"
SAVEHIST="10000"

HISTFILE="/home/hm-user/.zsh_history"
mkdir -p "$(dirname "$HISTFILE")"

setopt HIST_FCNTL_LOCK

# Enabled history options
enabled_opts=(
  HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
)
for opt in "${enabled_opts[@]}"; do
  setopt "$opt"
done
unset opt enabled_opts

# Disabled history options
disabled_opts=(
  APPEND_HISTORY EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS
  HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS
)
for opt in "${disabled_opts[@]}"; do
  unsetopt "$opt"
done
unset opt disabled_opts

source @zsh-history-substring-search@/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# Bind search up keys
search_up_keys=(
  '^[[A' '\eOA'
)
 for key in "${search_up_keys[@]}"; do
   bindkey "$key" history-substring-search-up
 done
 unset key search_up_keys

# Bind search down keys
search_down_keys=(
  '^[[B'
)
 for key in "${search_down_keys[@]}"; do
   bindkey "$key" history-substring-search-down
 done
 unset key search_down_keys

