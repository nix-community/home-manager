{ lib, pkgs, ... }:

with lib;

{
  config = {
    xsession.windowManager.bspwm = {
      enable = true;
      monitors.focused =
        [ "desktop 1" "d'esk top" ]; # pathological desktop names
      settings = {
        border_width = 2;
        split_ratio = 0.52;
        gapless_monocle = true;
        external_rules_command = "/path/to/external rules command";
        ignore_ewmh_fullscreen = [ "enter" "exit" ];
      };
      rules."*" = {
        sticky = true;
        center = false;
        desktop = "d'esk top#next";
        splitDir = "north";
        border = null;
      };
      extraConfig = ''
        extra config
      '';
      startupPrograms = [ "foo" "bar || qux" ];
    };

    test.stubs.bspwm = { };

    nmt.script = ''
      bspwmrc=home-files/.config/bspwm/bspwmrc
      assertFileExists "$bspwmrc"
      assertFileIsExecutable "$bspwmrc"
      assertFileContent "$bspwmrc" ${
        pkgs.writeShellScript "bspwmrc-expected" (readFile ./bspwmrc)
      }
    '';
  };
}
