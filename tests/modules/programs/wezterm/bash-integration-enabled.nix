{ ... }:

{
  programs.bash.enable = true;

  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
  };

  test.stubs.wezterm = { };

  nmt.script = ''
    assertFileContains home-files/.bashrc 'source "@wezterm@/etc/profile.d/wezterm.sh"'
  '';
}
