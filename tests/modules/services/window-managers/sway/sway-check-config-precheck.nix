{ config, lib, ... }:

lib.mkIf config.test.enableBig {
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;
    preCheckConfig = ''
      export HOME=$(mktemp -d)
      sed 's/mybg/otherbg/g' -i sway.conf
      touch ~/otherbg.png
    '';
    config.output."*".background = "~/mybg.png fill";
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileRegex home-files/.config/sway/config 'mybg\.png'
    assertFileNotRegex home-files/.config/sway/config 'otherbg\.png'
  '';
}
