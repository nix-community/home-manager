{ ... }:

{
  programs.zsh.enable = true;

  programs.wezterm = {
    enable = true;
    enableZshIntegration = false;
  };

  test.stubs.wezterm = { };
  test.stubs.zsh = { };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc 'source "@wezterm@/etc/profile.d/wezterm.sh"'
  '';
}
