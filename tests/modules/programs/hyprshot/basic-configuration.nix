{
  programs.hyprshot = {
    enable = true;
    saveLocation = "dummy";
  };

  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export HYPRSHOT_DIR="dummy"'
  '';
}
