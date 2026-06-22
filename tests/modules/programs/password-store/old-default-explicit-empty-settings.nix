{
  home.stateVersion = "25.05"; # <= 25.11
  programs.password-store = {
    enable = true;
    settings = { };
  };

  nmt.script = ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      '^export PASSWORD_STORE_DIR='
  '';
}
