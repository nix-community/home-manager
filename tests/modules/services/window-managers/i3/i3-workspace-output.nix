{ ... }:

let
  i3 = {
    ws1 = "1";
    ws2 = "ABC";
    ws3 = "3: Test";
    ws4 = ''!"§$%&/(){}[]=?\*#<>-_.:,;²³'';
    ws5 = "Multiple";
  };

in {
  imports = [ ./i3-stubs.nix ];

  xsession.windowManager.i3 = {
    enable = true;

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
    assertFileExists home-files/.config/i3/config
    assertFileContent home-files/.config/i3/config \
      ${./i3-workspace-output-expected.conf}
  '';
}
