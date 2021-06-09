{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.foot.enable = true;

    nixpkgs.overlays =
      [ (self: super: { foot = pkgs.writeScriptBin "dummy-foot" ""; }) ];

    nmt.script = ''
      assertFileExists home-files/.config/foot/foot.ini
      assertFileContent \
        home-files/.config/foot/foot.ini \
        ${builtins.toFile "test" ""}
    '';
  };
}
