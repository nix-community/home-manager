{ config, lib, ... }:

{
  imports = [ ./i3-stubs.nix ];

  xsession.windowManager.i3 = {
    enable = true;

    config.keybindings =
      let modifier = config.xsession.windowManager.i3.config.modifier;
      in lib.mkOptionDefault {
        "${modifier}+Left" = "overridden-command";
        "${modifier}+Right" = null;
        "${modifier}+Invented" = "invented-key-command";
      };
  };

  nmt.script = ''
    assertFileExists home-files/.config/i3/config
    assertFileContent home-files/.config/i3/config \
      ${./i3-keybindings-expected.conf}
  '';
}
