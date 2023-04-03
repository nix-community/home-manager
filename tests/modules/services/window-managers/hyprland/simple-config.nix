{ config, lib, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = lib.makeOverridable
      (attrs: config.lib.test.mkStubPackage { name = "hyprland"; }) { };
    plugins =
      [ "/path/to/plugin1" (config.lib.test.mkStubPackage { name = "foo"; }) ];
    settings = {
      decoration = {
        shadow_offset = "0 5";
        "col.shadow" = "rgba(00000099)";
      };

      "$mod" = "SUPER";

      input = {
        kb_layout = "ro";
        follow_mouse = 1;
        accel_profile = "flat";
        touchpad = { scroll_factor = 0.3; };
      };

      bindm = [
        # mouse movements
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];
    };
    extraConfig = ''
      # window resize
      bind = $mod, S, submap, resize

      submap = resize
      binde = , right, resizeactive, 10 0
      binde = , left, resizeactive, -10 0
      binde = , up, resizeactive, 0 -10
      binde = , down, resizeactive, 0 10
      bind = , escape, submap, reset
      submap = reset
    '';
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.conf
    assertFileExists "$config"

    normalizedConfig=$(normalizeStorePaths "$config")
    assertFileContent "$normalizedConfig" ${./simple-config.conf}
  '';
}
