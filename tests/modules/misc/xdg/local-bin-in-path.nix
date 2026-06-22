{
  xdg.enable = true;
  xdg.localBinInPath = true;

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export PATH="/home/hm-user/.local/bin''${PATH:+:}$PATH"'
  '';
}
