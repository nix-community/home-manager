{
  programs.zsh = {
    enable = true;

    shellAliases = {
      test1 = "alias";
      test2 = "alias2";
    };
    shellGlobalAliases = {
      global = "test";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc

    assertFileContent home-files/.zshrc ${builtins.toFile "expected-.zshrc" ''
      typeset -U path cdpath fpath manpath
      for profile in ''${(z)NIX_PROFILES}; do
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
      unsetopt APPEND_HISTORY
      unsetopt INC_APPEND_HISTORY
      unsetopt INC_APPEND_HISTORY_TIME
      unsetopt HIST_EXPIRE_DUPS_FIRST
      unsetopt EXTENDED_HISTORY
      unsetopt HIST_FIND_NO_DUPS
      unsetopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_SPACE
      unsetopt HIST_SAVE_NO_DUPS
      setopt SHARE_HISTORY


      alias -- test1=alias
      alias -- test2=alias2
      alias -g -- global=test''}
  '';
}
