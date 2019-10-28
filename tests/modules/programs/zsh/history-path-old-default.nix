{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "19.03";
    programs.zsh.enable = true;

    nixpkgs.overlays = [
      (self: super: {
        zsh = pkgs.writeScriptBin "dummy-zsh" "";
      })
    ];

    nmt.script = ''
      assertFileRegex home-files/.zshrc '^HISTFILE="$HOME/.zsh_history"$'
    '';
  };
}
