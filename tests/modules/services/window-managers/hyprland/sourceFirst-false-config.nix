{ config, lib, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = lib.makeOverridable
      (attrs: config.lib.test.mkStubPackage { name = "hyprland"; }) { };
    settings = {
      source = [ "sourced.conf" ];

      bezier = [
        "smoothOut, 0.36, 0, 0.66, -0.56"
        "smoothIn, 0.25, 1, 0.5, 1"
        "overshot, 0.4,0.8,0.2,1.2"
      ];

      input = {
        kb_layout = "ro";
        follow_mouse = 1;
        accel_profile = "flat";
        touchpad = { scroll_factor = 0.3; };
      };
    };
    sourceFirst = false;
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.conf
    assertFileExists "$config"

    normalizedConfig=$(normalizeStorePaths "$config")
    assertFileContent "$normalizedConfig" ${./sourceFirst-false-config.conf}
  '';
}
