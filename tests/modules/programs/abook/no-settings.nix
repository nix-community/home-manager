{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.abook.enable = true;

    nixpkgs.overlays =
      [ (self: super: { abook = pkgs.writeScriptBin "dummy-abook" ""; }) ];

    nmt.script = ''
      assertPathNotExists home-files/.config/abook/abookrc
    '';
  };
}
