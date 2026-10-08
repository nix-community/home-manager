{
  wayland.windowManager.niri = {
    enable = true;
    checkConfig = false;
    extraConfigEarly = "// early config";
    extraConfig = "// late config";
    settings = {
      # str/num/bool
      screenshot-path = "~/Screenshots/%Y-%m-%d %H-%M-%S.png";
      layout.gaps = 8;
      layout.shadow.draw-behind-window = true;

      # {} leaf node
      prefer-no-csd = { };
      input.touchpad.tap = { };

      # _props
      layout.shadow.offset._props = {
        x = 0;
        y = 5;
      };

      # _children
      layout.preset-column-widths._children = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
      ];

      # binds
      binds = {
        "Mod+H".focus-column-left = { };
        "Mod+Return" = {
          _props.hotkey-overlay-title = "Open a Terminal";
          spawn = [ "ghostty" ];
        };
        "XF86AudioRaiseVolume" = {
          _props.allow-when-locked = true;
          spawn = [
            "wpctl"
            "set-volume"
            "@DEFAULT_AUDIO_SINK@"
            "5%+"
          ];
        };
      };

      # _args for repeated/parameterized top-level nodes
      _children = [
        { workspace._args = [ "chat" ]; }
        { workspace._args = [ "dev" ]; }
        {
          output = {
            _args = [ "eDP-1" ];
            scale = 2.0;
          };
        }
        {
          window-rule._children = [
            {
              match._props = {
                app-id = "firefox";
                at-startup = true;
              };
            }
            { open-on-workspace = "dev"; }
          ];
        }
      ];
    };
  };

  test.stubs = {
    niri = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin $out/share/systemd/user $out/share/xdg-desktop-portal

        touch $out/bin/niri
        touch $out/bin/niri-session
        touch $out/share/systemd/user/niri.service
        touch $out/share/systemd/user/niri-shutdown.target
        touch $out/share/xdg-desktop-portal/niri-portals.conf
      '';
    };
    xwayland-satellite = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/xwayland-satellite
      '';
    };
    xdg-desktop-portal-gnome = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/share/xdg-desktop-portal/portals
        touch $out/share/xdg-desktop-portal/portals/gnome.portal
      '';
    };
  };

  nmt.script = ''
    niriConfig=home-files/.config/niri/config.kdl

    assertFileExists "$niriConfig"
    assertFileContent "$niriConfig" "${./niri-example-settings-expected.kdl}"

    assertFileExists home-path/bin/niri
    assertFileExists home-path/bin/niri-session
    assertFileExists home-path/bin/xwayland-satellite
    assertFileExists home-path/share/systemd/user/niri.service
    assertFileExists home-path/share/systemd/user/niri-shutdown.target
    assertFileExists home-path/share/xdg-desktop-portal/niri-portals.conf
    assertFileExists home-path/share/xdg-desktop-portal/portals/gnome.portal
  '';
}
