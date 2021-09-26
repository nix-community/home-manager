{ config, lib, ... }:

{
  imports = [ ./i3-stubs.nix ];

  xsession.windowManager.i3 = {
    enable = true;

    config.defaultWorkspace = "workspace number 1";
  };

  nmt.script = ''
    assertFileExists home-files/.config/i3/config
    assertFileContent home-files/.config/i3/config \
      ${./i3-workspace-default-expected.conf}
  '';
}
