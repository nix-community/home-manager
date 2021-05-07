{ config, lib, ... }:

with lib;

{
  config = {
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

    nixpkgs.overlays = [ (import ./i3-overlay.nix) ];

    nmt.script = ''
      assertFileExists home-files/.config/i3/config
      assertFileContent home-files/.config/i3/config \
        ${./i3-keybindings-expected.conf}
    '';
  };
}
