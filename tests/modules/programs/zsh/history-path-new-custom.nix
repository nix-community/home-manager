{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "20.03";
    programs.zsh = {
      enable = true;
      history.path = "$HOME/some/directory/zsh_history";
    };

    nixpkgs.overlays =
      [ (self: super: { zsh = pkgs.writeScriptBin "dummy-zsh" ""; }) ];

    nmt.script = ''
      assertFileRegex $home_files/.zshrc '^HISTFILE="$HOME/some/directory/zsh_history"$'
    '';
  };
}
