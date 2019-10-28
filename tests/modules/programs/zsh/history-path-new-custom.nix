{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "20.03";
    programs.zsh = {
      enable = true;
      history.path = "$HOME/some/directory/zsh_history";
    };

    nmt.script = ''
      assertFileRegex home-files/.zshrc '^HISTFILE="$HOME/some/directory/zsh_history"$'
    '';
  };
}
