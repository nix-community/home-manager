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
        mpvScript =
          pkgs.runCommandLocal "mpvScript" { scriptName = "something"; }
          "mkdir $out";
      })
    ];
    test.stubs.mpvDummy = { };

    test.asserts.assertions.expected = [
      ''
        The programs.mpv "package" option is mutually exclusive with "scripts" option.''
    ];
  };
}
