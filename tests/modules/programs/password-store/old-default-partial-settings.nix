{
  home.stateVersion = "25.05"; # <= 25.11
  programs.password-store = {
    enable = true;
    settings.PASSWORD_STORE_KEY = "12345678";
  };

  nmt.script = ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      '^export PASSWORD_STORE_DIR='
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export PASSWORD_STORE_KEY="12345678"'
  '';
}
