{
  config,
  lib,
  realPkgs,
  ...
}:

lib.mkIf config.test.enableBig {
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = true;
    package = realPkgs.sway;
  };

  nixpkgs.overlays = [ (_self: _super: { inherit (realPkgs) xvfb-run; }) ];

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
  '';
}
