{ config, lib, ... }: {
  imports = [ ./hyprland-stubs.nix ];

  wayland.windowManager.hyprland = {
    enable = true;

    package = lib.makeOverridable
      (_: config.lib.test.mkStubPackage { name = "hyprland"; }) { };
    portalPackage = null;

    settings = {
      cursor = {
        enable_hyprcursor = true;
        sync_gsettings_theme = true;
      };
    };
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.conf
    assertFileExists "$config"
  '';
}
