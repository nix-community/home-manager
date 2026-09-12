{ config, lib, ... }:
{
  programs.rofi = {
    enable = true;
    configPath = "${config.xdg.configHome}/rofi/alternate.rasi";
    theme = "Arc";
    settings = lib.mkDefault {
      location = 2;
      font = "monospace 12";
      cycle = null;
      modes = [
        "drun"
        "custom:/some/script"
      ];
      matching = config.lib.formats.rasi.mkLiteral "normal";
      filebrowser = {
        directories-first = true;
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/rofi/alternate.rasi ${./basic-configuration.rasi}
    assertPathNotExists home-files/.config/rofi/config.rasi
  '';
}
