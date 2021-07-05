{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.foot.enable = true;

    nixpkgs.overlays =
      [ (self: super: { foot = pkgs.writeScriptBin "dummy-foot" ""; }) ];

    nmt.script = ''
      assertPathNotExists home-files/.config/foot
    '';
  };
}
