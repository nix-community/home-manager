{ config, lib, pkgs, ... }:

with lib;

let expected = builtins.toFile "settings-expected" "\n\n\n\n\n\n\n\n\n\n\n";
in {
  config = {
    programs.lf = { enable = true; };

    nixpkgs.overlays =
      [ (self: super: { lf = pkgs.writeScriptBin "dummy-lf" ""; }) ];

    nmt.script = ''
      assertFileExists $home_files/.config/lf/lfrc
      assertFileContent $home_files/.config/lf/lfrc ${expected}
    '';
  };
}
