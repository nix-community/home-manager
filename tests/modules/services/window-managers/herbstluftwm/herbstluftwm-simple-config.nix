{ lib, pkgs, ... }:

{
  xsession.windowManager.herbstluftwm = {
    enable = true;
    settings = {
      always_show_frame = true;
      default_frame_layout = "max";
      frame_bg_active_color = "#000000";
      frame_gap = 12;
      frame_padding = -12;
    };
    keybinds = {
      "Mod4-1" = "use 1";
      "Mod4-2" = "use 2";
      "Mod4-Tab" = "cycle 1";
      "Mod4-Alt-Tab" = "cycle -1";
    };
    mousebinds = {
      "Mod4-B1" = "move";
      "Mod4-B3" = "resize";
    };
    rules = [
      "focus=on"
      "windowtype~'_NET_WM_WINDOW_TYPE_(DIALOG|UTILITY|SPLASH)' focus=on pseudotile=on"
      "class~'[Pp]inentry' instance=pinentry focus=on floating=on floatplacement=center keys_inactive='.*'"
    ];
    tags = [ "1" "with space" "wə1rd#ch@rs'" ];
    extraConfig = ''
      herbstclient use 1
    '';
  };

  test.stubs.herbstluftwm = { };

  nmt.script = ''
    autostart=home-files/.config/herbstluftwm/autostart
    assertFileExists "$autostart"
    assertFileIsExecutable "$autostart"

    normalizedAutostart=$(normalizeStorePaths "$autostart")
    assertFileContent "$normalizedAutostart" ${
      ./herbstluftwm-simple-config-autostart
    }
  '';
}
