{ ... }:

{
  programs.zsh.enable = true;

  # Zsh integration is enabled by default.
  programs.wezterm.enable = true;

  test.stubs.wezterm = { };
  test.stubs.zsh = { };

  nmt.script = ''
    assertFileContains home-files/.zshrc 'source "@wezterm@/etc/profile.d/wezterm.sh"'
  '';
}
