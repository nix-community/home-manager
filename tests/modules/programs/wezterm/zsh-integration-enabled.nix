{
  programs.zsh.enable = true;

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
  };

  nmt.script = ''
    assertFileContains home-files/.zshrc 'source "@wezterm@/etc/profile.d/wezterm.sh"'
  '';
}
