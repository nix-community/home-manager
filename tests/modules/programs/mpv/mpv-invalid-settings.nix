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
        mpv-unwrapped = pkgs.runCommandLocal "mpv" {
          version = "0";
          passthru = {
            lua.luaversion = "0";
            luaEnv = "/dummy";
            vapoursynthSupport = false;
          };
        } ''
          mkdir -p $out/bin $out/Applications/mpv.app/Contents/MacOS
          touch $out/bin/{,u}mpv $out/Applications/mpv.app/Contents/MacOS/mpv
          chmod 755 $out/bin/{,u}mpv $out/Applications/mpv.app/Contents/MacOS/mpv
        '';
        mpvDummy = config.lib.test.mkStubPackage { };
        mpvScript =
          pkgs.runCommandLocal "mpvScript" { scriptName = "something"; }
          "mkdir $out";
      })
    ];

    test.asserts.assertions.expected = [
      ''
        The programs.mpv "package" option is mutually exclusive with "scripts" option.''
    ];
  };
}
