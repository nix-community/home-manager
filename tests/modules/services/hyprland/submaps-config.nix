{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";

      bind = [
        "$mod, S, submap, resize"
        "$mod, M, submap, move_focus"
      ];
    };
    submaps = {
      resize = {
        settings = {
          binde = [
            ", right, resizeactive, 10 0"
            ", left, resizeactive, -10 0"
            ", up, resizeactive, 0 -10"
            ", down, resizeactive, 0 10"
            ", l, resizeactive, 10 0"
            ", h, resizeactive, -10 0"
            ", k, resizeactive, 0 -10"
            ", j, resizeactive, 0 10"
          ];

          bind = [
            ", escape, submap, reset"
            ", return, submap, reset"
          ];
        };
      };

      move_focus = {
        settings = {
          bind = [
            ", h, movefocus, l"
            ", j, movefocus, d"
            ", k, movefocus, u"
            ", l, movefocus, r"
            ", left, movefocus, l"
            ", down, movefocus, d"
            ", up, movefocus, u"
            ", right, movefocus, r"
            ", escape, submap, reset"
          ];
        };
      };
    };
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.conf
    assertFileExists "$config"

    normalizedConfig=$(normalizeStorePaths "$config")
    assertFileContent "$normalizedConfig" ${./submaps-config.conf}
  '';
}
