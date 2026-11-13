{ config, ... }:
{
  xdg.configHome = "${config.home.homeDirectory}/.xdgconfig";
  programs.pomo = {
    enable = true;
    settings.work.duration = "25m";
  };
  nmt.script = ''
    assertFileExists home-files/.config/pomo/pomo.yaml
  '';
}
