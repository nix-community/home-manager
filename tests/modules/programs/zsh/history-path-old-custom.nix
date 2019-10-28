{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "19.09";
    programs.zsh = {
      enable = true;
      history.path = "some/directory/zsh_history";
    };

    nixpkgs.overlays = [
      (self: super: {
        zsh = pkgs.writeScriptBin "dummy-zsh" "";
      })
    ];

    nmt.script = ''
      assertFileRegex home-files/.zshrc '^HISTFILE="$HOME/some/directory/zsh_history"$'
    '';
  };
}
