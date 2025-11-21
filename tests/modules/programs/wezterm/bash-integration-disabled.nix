{
  programs.bash.enable = true;

  programs.wezterm = {
    enable = true;
    enableBashIntegration = false;
  };

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc 'source "@wezterm@/etc/profile.d/wezterm.sh"'
  '';
}
