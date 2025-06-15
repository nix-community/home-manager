{ config, ... }:
let
  mod = "mod4";
  left = "h";
  right = "l";
  down = "j";
  up = "k";
  font = "DeepMind Sans 10";
in
{
  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    checkConfig = false;
    config = null;

    settings = {
      bar = {
        inherit font;
        position = "top";
        colors = {
          background = "#000000";
          focused_workspace = "#000000 #000000 #ffba08";
          inactive_workspace = "#000000 #000000 #cde4e6";
        };
      };

      bindgesture = {
        "swipe:left" = "workspace next";
        "swipe:right" = "workspace prev";
      };
      input = {
        "type:touchpad" = {
          dwt = "enabled";
          tap = "enabled";
          natural_scroll = "enabled";
        };
        "type:keyboard" = {
          repeat_rate = 100;
          repeat_delay = 250;
        };
      };

      bindsym = {
        # basics
        "${mod}+q" = "kill";
        "${mod}+shift+c" = "reload";
        "${mod}+shift+e" = ''
          	  exec swaynag -t warning -m 'Do you really want to exit sway?' \
          	      -B 'Yes, exit sway' 'swaymsg exit'
          	'';

        # workspaces
        "${mod}+1" = "workspace number 1";
        "${mod}+2" = "workspace number 2";
        "${mod}+3" = "workspace number 3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number 8";
        "${mod}+9" = "workspace number 9";
        "${mod}+tab" = "workspace back_and_forth";
        "${mod}+shift+1" = "move container to workspace number 1";
        "${mod}+shift+2" = "move container to workspace number 2";
        "${mod}+shift+3" = "move container to workspace number 3";
        "${mod}+shift+4" = "move container to workspace number 4";
        "${mod}+shift+5" = "move container to workspace number 5";
        "${mod}+shift+6" = "move container to workspace number 6";
        "${mod}+shift+7" = "move container to workspace number 7";
        "${mod}+shift+8" = "move container to workspace number 8";
        "${mod}+shift+9" = "move container to workspace number 9";
        "${mod}+c" = "splitv";
        "${mod}+v" = "splith";

        # layout
        "${mod}+${left}" = "focus left";
        "${mod}+${down}" = "focus down";
        "${mod}+${up}" = "focus up";
        "${mod}+${right}" = "focus right";
        "${mod}+shift+${left}" = "move left";
        "${mod}+shift+${right}" = "move right";
        "${mod}+shift+${down}" = "move down";
        "${mod}+shift+${up}" = "move up";
        "${mod}+f" = "fullscreen";
        "${mod}+s" = "layout stacking";
        "${mod}+t" = "layout tabbed";
        "${mod}+e" = "layout toggle split";
        "${mod}+shift+space" = "floating toggle";
        "${mod}+r" = "mode resize";

        # scratchpad
        "${mod}+shift+minus" = "move scratchpad";
        "${mod}+minus" = "scratchpad show";
      };

      mode.resize.bindsym = {
        ${left} = "resize shrink width 10px";
        ${right} = "resize grow width 10px";
        ${down} = "resize grow height 10px";
        ${up} = "resize shrink height 10px";
        return = "mode default";
      };

      gaps.inner = 10;
      default_border.pixel = 2;
      floating_modifier = "${mod} normal";
      "client.focused" = "#4c7899 #285577 #ffffff #285577";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
      ${./sway-settings.conf}
  '';
}
