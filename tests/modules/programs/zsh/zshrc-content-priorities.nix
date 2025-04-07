{ lib, pkgs, ... }:
{
  programs.zsh = {
    enable = true;

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # High priority (mkBefore)
        echo "High priority content"
      '')

      (lib.mkAfter ''
        # Low priority (mkAfter)
        echo "Low priority content"
      '')

      ''
        # Default priority
        echo "Default priority content"
      ''
    ];

    zprof.enable = true;
  };

  nmt.script =
    let
      expectedFile = pkgs.writeTextFile {
        name = ".zshrc";
        text = ''
          zmodload zsh/zprof

          # High priority (mkBefore)
          echo "High priority content"

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

          HISTFILE="$HOME/.zsh_history"
          mkdir -p "$(dirname "$HISTFILE")"

          setopt HIST_FCNTL_LOCK
          unsetopt APPEND_HISTORY
          setopt HIST_IGNORE_DUPS
          unsetopt HIST_IGNORE_ALL_DUPS
          unsetopt HIST_SAVE_NO_DUPS
          unsetopt HIST_FIND_NO_DUPS
          setopt HIST_IGNORE_SPACE
          unsetopt HIST_EXPIRE_DUPS_FIRST
          setopt SHARE_HISTORY
          unsetopt EXTENDED_HISTORY


          # Default priority
          echo "Default priority content"

          zprof
          # Low priority (mkAfter)
          echo "Low priority content"
        '';
      };
    in
    ''
      assertFileExists home-files/.zshrc
      assertFileContent home-files/.zshrc ${expectedFile}
    '';
}
