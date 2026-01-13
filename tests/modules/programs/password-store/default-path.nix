{
  home.stateVersion = "25.11"; # Or any other newer version
  programs.password-store.enable = true;

  nmt.script = ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      '^export PASSWORD_STORE_DIR='
  '';
}
