{ config, lib, ... }:

{
  imports = [ ./i3-stubs.nix ];

  xsession.windowManager.i3 = {
    enable = true;

    config.bars = [{
      colors.focusedBackground = "#ffffff";
      colors.focusedStatusline = "#000000";
      colors.focusedSeparator = "#999999";
    }];
  };

  nmt.script = ''
    assertFileExists home-files/.config/i3/config
    assertFileContent home-files/.config/i3/config \
      ${./i3-bar-focused-colors-expected.conf}
  '';
}
