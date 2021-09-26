{ config, lib, ... }:

{
  imports = [ ./i3-stubs.nix ];

  xsession.windowManager.i3 = {
    enable = true;

    config = {
      bars = [{
        fonts = {
          names = [ "FontAwesome" "Iosevka" ];
          size = 11.5;
        };
      }];
      fonts = {
        names = [ "DejaVuSansMono" "Terminus" ];
        style = "Bold Semi-Condensed";
        size = 13.5;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/i3/config
    assertFileContent home-files/.config/i3/config \
      ${./i3-fonts-expected.conf}
  '';
}
