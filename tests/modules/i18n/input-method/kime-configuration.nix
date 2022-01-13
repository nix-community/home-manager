{ config, pkgs, ... }:

{
  i18n.inputMethod = {
    enabled = "kime";
    kime.config = { engine = { hangul = { layout = "dubeolsik"; }; }; };
  };

  test.stubs.kime = { outPath = null; };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/kime-daemon.service
  '';
}
