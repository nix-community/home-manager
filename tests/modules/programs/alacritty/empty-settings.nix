{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.alacritty.enable = true;

    nixpkgs.overlays = [
      (self: super: {
        alacritty = pkgs.writeScriptBin "dummy-alacritty" "";
      })
    ];

    nmt.script = ''
      assertPathNotExists home-files/.config/alacritty
    '';
  };
}
