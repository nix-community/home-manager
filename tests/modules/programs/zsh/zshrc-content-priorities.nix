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

          HISTFILE="/home/hm-user/.zsh_history"
          mkdir -p "$(dirname "$HISTFILE")"

          # Set shell options
          set_opts=(
            HIST_FCNTL_LOCK HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
            NO_APPEND_HISTORY NO_EXTENDED_HISTORY NO_HIST_EXPIRE_DUPS_FIRST
            NO_HIST_FIND_NO_DUPS NO_HIST_IGNORE_ALL_DUPS NO_HIST_SAVE_NO_DUPS
          )
          for opt in "''${set_opts[@]}"; do
            setopt "$opt"
          done
          unset opt set_opts

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
