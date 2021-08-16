{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.htop.enable = true;

    nixpkgs.overlays =
      [ (self: super: { htop = pkgs.writeScriptBin "dummy" ""; }) ];

    nmt.script = ''
      assertPathNotExists home-files/.config/htop
    '';
  };
}
