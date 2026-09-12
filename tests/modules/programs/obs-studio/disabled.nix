{ config, lib, ... }:
{
  programs.obs-studio = {
    enable = false;
    settings.global.General.MaxLogs = 10;
    sceneCollections.Streaming.name = "Streaming";
  };
  nmt.script = ''
    test ${
      if
        lib.any (file: lib.hasPrefix ".config/obs-studio/" file.target) (lib.attrValues config.home.file)
      then
        "true"
      else
        "false"
    } = false
    assertPathNotExists home-files/.config/obs-studio
  '';
}
