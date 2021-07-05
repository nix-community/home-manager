{ config, lib, ... }:

with lib;

{
  config = {
    xsession.windowManager.i3 = {
      enable = true;

      config.defaultWorkspace = "workspace number 1";
    };

    nixpkgs.overlays = [ (import ./i3-overlay.nix) ];

    nmt.script = ''
      assertFileExists home-files/.config/i3/config
      assertFileContent home-files/.config/i3/config \
        ${./i3-workspace-default-expected.conf}
    '';
  };
}
