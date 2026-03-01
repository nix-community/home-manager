{ config, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    submaps = {
      resize = {
        onDispatch = "reset";
        settings = {
          binde = [
            ", right, resizeactive, 10 0"
            ", left, resizeactive, -10 0"
          ];
        };
      };
      other = {
        onDispatch = "resize";
        settings = {
          bind = [ ", a, exec, true" ];
        };
      };
    };
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.conf
    assertFileExists "$config"
    assertFileContains "$config" "submap = resize, reset"
    assertFileContains "$config" "submap = other, resize"
  '';
}
