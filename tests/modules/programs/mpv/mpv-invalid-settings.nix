{ config, lib, pkgs, ... }:

{
  config = {
    programs.mpv = {
      enable = true;
      package = pkgs.mpvDummy;
      scripts = [ pkgs.mpvScript ];
    };

    nixpkgs.overlays = [
      (self: super: {
        mpvDummy = pkgs.runCommandLocal "mpv" { } "mkdir $out";
        mpvScript =
          pkgs.runCommandLocal "mpvScript" { scriptName = "something"; }
          "mkdir $out";
      })
    ];

    home.file.result.text = builtins.toJSON
      (map (a: a.message) (lib.filter (a: !a.assertion) config.assertions));

    nmt.script = ''
      assertFileContent \
         home-files/result \
         ${./mpv-invalid-settings-expected.json}
    '';
  };
}
