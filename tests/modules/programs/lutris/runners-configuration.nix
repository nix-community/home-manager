{ pkgs, lib, ... }:
{
  programs.lutris = {
    enable = true;
    runners = {
      cemu.package = pkgs.cemu;
      pcsx2.settings = {
        system.disable_screen_saver = true;
        runner.executable_path = "${pkgs.pcsx2}/bin/pcsx2-qt";
      };
      rpcs3 = {
        package = pkgs.rpcs3;
        settings = {
          system.disable_screen_saver = true;
          runner.nogui = true;
        };
      };
    };
  };

  nmt.script =
    let
      runnersDir = "home-files/.config/lutris/runners";
      expectedCemu = builtins.toFile "cemu.yml" ''
        cemu:
          executable_path: '${lib.getExe pkgs.cemu}'
      '';
      expectedPcsx2 = builtins.toFile "pcsx2.yml" ''
        pcsx2:
          executable_path: '${pkgs.pcsx2}/bin/pcsx2-qt'
        system:
          disable_screen_saver: true
      '';
      expectedRpcs3 = builtins.toFile "rpcs3.yml" ''
        rpcs3:
          executable_path: '${lib.getExe pkgs.rpcs3}'
          nogui: true
        system:
          disable_screen_saver: true
      '';
    in
    ''
      assertFileExists ${runnersDir}/cemu.yml
      assertFileContent ${runnersDir}/cemu.yml ${expectedCemu}
      assertFileExists ${runnersDir}/pcsx2.yml
      assertFileContent ${runnersDir}/pcsx2.yml ${expectedPcsx2}
      assertFileExists ${runnersDir}/rpcs3.yml
      assertFileContent ${runnersDir}/rpcs3.yml ${expectedRpcs3}
    '';
}
