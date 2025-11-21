{
  programs.wezterm = {
    enable = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/wezterm/wezterm.lua
  '';
}
