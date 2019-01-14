{ config, lib, ... }:

with lib;

{
  config = {
    xsession.windowManager.i3 = {
      enable = true;

      config.keybindings =
        let
          modifier = config.xsession.windowManager.i3.config.modifier;
        in
          lib.mkOptionDefault {
            "${modifier}+Left" = "overridden-command";
            "${modifier}+Right" = null;
            "${modifier}+Invented" = "invented-key-command";
          };
    };

    nmt.script = ''
      assertFileExists home-files/.config/i3/config

      assertFileRegex home-files/.config/i3/config \
        'bindsym Mod1+Left overridden-command'

      assertFileNotRegex home-files/.config/i3/config \
        'Mod1+Right'

      assertFileRegex home-files/.config/i3/config \
        'bindsym Mod1+Invented invented-key-command'
    '';
  };
}
