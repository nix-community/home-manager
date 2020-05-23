{ config, lib, pkgs, ... }:

with lib;

let
  pvScript = builtins.toFile "pv.sh" "cat $1";
  expected = builtins.toFile "settings-expected" ''








    set previewer ${pvScript}



    # More config...

  '';
in {
  config = {
    programs.lf = {
      enable = true;

      extraConfig = ''
        # More config...
      '';

      previewer = { source = pvScript; };
    };

    nixpkgs.overlays =
      [ (self: super: { lf = pkgs.writeScriptBin "dummy-lf" ""; }) ];

    nmt.script = ''
      assertFileExists $home_files/.config/lf/lfrc
      assertFileContent $home_files/.config/lf/lfrc ${expected}
    '';
  };
}
