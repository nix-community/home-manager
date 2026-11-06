{ config, ... }:

{
  programs.kakoune = {
    enable = true;
    linkAutoload = true;
  };

  nmt.script = ''
    assertLinkPointsTo home-files/.config/kak/autoload/rc ${config.programs.kakoune.finalPackage}/share/kak/autoload/rc
  '';
}
