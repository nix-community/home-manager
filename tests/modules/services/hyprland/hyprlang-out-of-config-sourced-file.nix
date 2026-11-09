{
  config,
  lib,
  realPkgs,
  ...
}:

# Regression tests: Verify that we do not broke valid configuration that source externally provided hyprlang's files.
lib.mkIf config.test.enableBig {
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    package = realPkgs.hyprland;
    settings = {
      source = [ "sourced.conf" ];
    };
  };

  xdg.configFile."hypr/sourced.conf".text = ''
    general {}
  '';

  test.assertFileExists = [
    "home-files/.config/hypr/hyprland.conf"
    "home-files/.config/hypr/sourced.conf"
  ];
}
