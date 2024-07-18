{ config, lib, pkgs, ... }:

let
  i3 = {
    ws1 = "1";
    ws2 = "ABC";
    ws3 = "3: Test";
    ws4 = ''!"§$%&/(){}[]=?\*#<>-_.:,;²³'';
    ws5 = "Multiple";
  };

in {
  imports = [ ./sway-stubs.nix ];

  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    checkConfig = false;
    # overriding findutils causes issues
    config.menu = "${pkgs.dmenu}/bin/dmenu_run";

    config.workspaceOutputAssign = [
      {
        workspace = "${i3.ws1}";
        output = "eDP";
      }
      {
        workspace = "${i3.ws2}";
        output = "DP";
      }
      {
        workspace = "${i3.ws3}";
        output = "HDMI";
      }
      {
        workspace = "${i3.ws4}";
        output = "DVI";
      }
      {
        workspace = "${i3.ws5}";
        output = [ "DVI" "HDMI" "DP" ];
      }
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
      ${./sway-workspace-output-expected.conf}
  '';
}
