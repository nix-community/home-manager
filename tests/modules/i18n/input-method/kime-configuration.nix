{ config, pkgs, ... }:

{
  i18n.inputMethod = {
    enabled = "kime";
    kime.config = { engine = { hangul = { layout = "dubeolsik"; }; }; };
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/kime-daemon.service
  '';
}
