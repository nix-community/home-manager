{ config, lib, ... }:

{
  imports = [ ./i3-stubs.nix ];

  xsession.windowManager.i3 = {
    enable = true;

    config = {
      bars = [{ fonts = [ "FontAwesome" "Iosevka 11.500000" ]; }];
      fonts = [ "DejaVuSansMono" "Terminus Bold Semi-Condensed 13.500000" ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/i3/config
    assertFileContent home-files/.config/i3/config \
      ${./i3-fonts-expected.conf}
  '';

  test.asserts.warnings.expected = [
    "Specifying i3.config.fonts as a list is deprecated. Use the attrset version instead."
    "Specifying i3.config.bars[].fonts as a list is deprecated. Use the attrset version instead."
  ];
}
