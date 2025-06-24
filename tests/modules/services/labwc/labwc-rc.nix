{
  wayland.windowManager.labwc = {
    enable = true;
    package = null;
    rc = {
      theme = {
        name = "nord";
        cornerRadius = 8;
        font = {
          "@name" = "FiraCode";
          "@place" = "";
          "@size" = "11";
        };
      };
      mouse = {
        default = { };
        context = {
          "@name" = "Root";
          mousebind = [
            {
              "@button" = "Right";
              "@action" = "Press";
              action = {
                "@name" = "ShowMenu";
                "@menu" = "some-custom-menu";
              };
            }
          ];
        };
      };
      keyboard = {
        default = true;
        keybind = [
          {
            "@key" = "W-Return";
            action = {
              "@command" = "alacritty";
              "@name" = "Execute";
            };
          }
          {
            "@key" = "W-Esc";
            action = {
              "@name" = "Execute";
              "@command" = "foot";
            };
          }
          {
            "@key" = "W-1";
            action = {
              "@to" = "1";
              "@name" = "GoToDesktop";
            };
          }
        ];
      };
      desktops = {
        "@number" = 10;
      };
    };
    extraConfig = ''
      <!-- ExtraConfig -->
      <tabletTool motion="absolute" relativeMotionSensitivity="1.0" />
      <libinput>
        <device category="default">
          <naturalScroll></naturalScroll>
          <leftHanded></leftHanded>
          <pointerSpeed></pointerSpeed>
          <accelProfile></accelProfile>
        </device>
      </libinput>
    '';
  };

  nmt.script = ''
    labwcConfig=home-files/.config/labwc/rc.xml

    assertFileExists "$labwcConfig"
    assertFileContent "$labwcConfig" "${./rc.xml}"
  '';
}
