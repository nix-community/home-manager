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

      animations = {
        enabled = true;
        animation = [
          "border, 1, 2, smoothIn"
          "fade, 1, 4, smoothOut"
          "windows, 1, 3, overshot, popin 80%"
        ];
      };

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
