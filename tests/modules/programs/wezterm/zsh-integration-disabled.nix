{
  programs.zsh.enable = true;

  programs.wezterm = {
    enable = true;
    enableZshIntegration = false;
  };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc 'source "@wezterm@/etc/profile.d/wezterm.sh"'
  '';
}
