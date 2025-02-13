{
  programs.bash.enable = true;

  # Bash integration is enabled by default.
  programs.wezterm.enable = true;

  nmt.script = ''
    assertFileContains home-files/.bashrc 'source "@wezterm@/etc/profile.d/wezterm.sh"'
  '';
}
