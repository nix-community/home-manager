{ config, lib, ... }:

with lib;

{
  config = let
    i3 = {
      ws1 = "1: ABC";
      ws2 = "2: DEF";
      ws3 = "3: XYZ";
    };

  in {
    xsession.windowManager.i3 = {
      enable = true;

      config.workspaceOutputAssign = [
        {
          workspace = "${i3.ws1}";
          output = "eDP-1";
        }
        {
          workspace = "${i3.ws2}";
          output = "HDMI-1";
        }
        {
          workspace = "${i3.ws3}";
          output = "eDP-1";
        }
      ];
    };

    nixpkgs.overlays = [ (import ./i3-overlay.nix) ];

    nmt.script = ''
      assertFileExists home-files/.config/i3/config
      assertFileContent home-files/.config/i3/config \
        ${./i3-workspace-output-expected.conf}
    '';
  };
}
