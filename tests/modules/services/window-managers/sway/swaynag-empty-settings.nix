{ ... }:

{
  wayland.windowManager.sway.swaynag = {
    enable = true;

    settings = { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/swaynag
  '';
}
