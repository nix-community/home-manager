{ config, ... }:
{
  programs.telegram = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@telegram@"; };
    systemd = {
      enable = true;
      targets = [ "tray.target" ];
      extraArgs = [
        "-startintray"
        "-scale 75"
      ];
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.local/share/TelegramDesktop

    assertFileContent\
     home-files/.config/systemd/user/telegram.service\
     ${./systemd.service}
  '';
}
