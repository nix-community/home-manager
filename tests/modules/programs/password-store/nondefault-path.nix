let
  somePath = "/some/random/path/I/store/pwds";
in
{
  home.stateVersion = "25.11";
  programs.password-store = {
    enable = true;
    settings.PASSWORD_STORE_DIR = somePath;
  };

  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export PASSWORD_STORE_DIR="${somePath}"'
  '';
}
