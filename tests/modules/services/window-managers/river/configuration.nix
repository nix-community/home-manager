{ ... }:

{
  wayland.windowManager.river = {
    enable = true;
    xwayland.enable = true;
    extraSessionVariables = {
      FOO = "foo";
      BAR = "bar";
      FOURTY_TWO = 42;
    };
    # systemdIntegration = true;
    settings = {
      attach-mode = "bottom";
      background-color = "0x002b36";
      border-color-focused = "0x93a1a1";
      border-color-unfocused = "0x586e75";
      border-color-urgent = "0xff0000";
      border-width = 2;
      csd-filter-add.app-id = [ "bar" "foo" ];
      declare-mode = [ "locked" "normal" "passthrough" ];
      default-layout = "rivertile";
      float-filter-add.app-id = "mpd";
      float-filter-add.title = "popup title with spaces";
      focus-follows-cursor = "normal";
      hide-cursor.timeout = 2;
      hide-cursor.when-typing = true;
      input.pointer-foo-bar = {
        accel-profile = "flat";
        events = true;
        pointer-accel = -0.3;
        tap = false;
      };
      keyboard-layout."-variant".colemak."-options"."altwin:swap_alt_wincaps:escapegrp:alt_shift_toggle" =
        "us,de";
      map.locked.None.XF86AudioLowerVolume.spawn = "'pamixer -d 5'";
      map.locked.None.XF86AudioRaiseVolume.spawn = "'pamixer -i 5'";
      map.normal."Alt E" = "toggle-fullscreen";
      map.normal."Alt P" = "enter-mode passthrough";
      map.normal."Alt Q" = "close";
      map.normal."Alt Return" = "spawn foot";
      map.normal."Alt T" = "toggle-float";
      map.passthrough."Alt P" = "enter-mode normal";
      map-pointer.normal."Alt BTN_LEFT" = "move-view";
      map-pointer.normal."Super BTN_LEFT" = "move-view";
      map-pointer.normal."Super BTN_MIDDLE" = "toggle-float";
      map-pointer.normal."Super BTN_RIGHT" = "resize-view";
      map-switch = {
        locked = {
          lid.open = "foo";
          tablet.on = "foo";
        };
        normal = {
          lid = {
            close = "foo";
            open = "foo";
          };
          tablet = {
            off = "foo bar";
            on = "foo";
          };
        };
      };
      rule-add."-app-id" = {
        "'bar'" = "csd";
        "'float*'"."-title"."'foo'" = "float";
      };
      set-cursor-warp = "on-output-change";
      set-repeat = "50 300";
      xcursor-theme = "someGreatTheme 12";
      spawn = [ "firefox" "'foot -a terminal'" ];
    };

    extraConfig = ''
      rivertile -view-padding 6 -outer-padding 6 &
      some
      extra config
    '';
  };

  test.stubs = {
    dbus = { };
    river = { };
    xwayland = { };
  };

  nmt.script = ''
    riverInit=home-files/.config/river/init
    assertFileExists "$riverInit"
    assertFileIsExecutable "$riverInit"

    normalizedConfig=$(normalizeStorePaths "$riverInit")
    assertFileContent "$normalizedConfig" "${./init}"
  '';
}
