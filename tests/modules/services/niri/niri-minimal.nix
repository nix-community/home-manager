{ config, ... }:

{
  wayland.windowManager.niri = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@niri@"; };
    config = {
      input = {
        keyboard = {
          xkb = {
            layout = "us";
            file = "~/.config/keymap.xkb";
          };
          numlock = true;
        };
        touchpad = {
          tap = true;
          naturalScroll = true;
        };
        mouse = {
          accelSpeed = 0.2;
        };
        trackpoint = {
          off = true;
          leftHanded = true;
        };
      };
      workspaces = {
        music = { };
        web = {
          openOnOutput = "DP-2";
          layout.gaps = 32;
        };
      };
      outputs = {
        "eDP-1".mode = "1920x1080@120.030";
        "HDMI-A-1".off = true;
      };
      windowRules = [
        {
          matches = [
            { title = "Firefox"; }
            { isActive = true; }
          ];
          opacity = 0.5;
          shadow = {
            drawBehindWindow = true;
          };
        }
        {
          matches = [ { appId = "^org\\\\.telegram\\\\.desktop$"; } ];
          excludes = [ { title = "^Media viewer$"; } ];
          openOnOutput = "HDMI-A-1";
        }
      ];
      layerRules = [
        {
          matches = [
            { namespace = "waybar"; }
          ];

          shadow = {
            off = true;
            drawBehindWindow = false;
          };
        }
        {
          matches = [
            { namespace = "waybar"; }
            { atStartup = true; }
          ];
          opacity = 0.5;
          blockOutFrom = "screencast";

          shadow = {
            on = true;
            softness = 40;
            spread = 5;
            offset = {
              x = 0;
              y = 5;
            };
            drawBehindWindow = true;
            color = "#00000064";
          };

          geometryCornerRadius = 12;
          placeWithinBackdrop = true;
          babaIsFloat = true;
        }
      ];
      layout = {
        alwaysCenterSingleColumn = true;
        backgroundColor = "#003300";
        border = {
          activeGradient = {
            from = "#ffbb66";
            to = "#ffc880";
            angle = 45;
            relativeTo = "workspace-view";
          };
          inactiveGradient = {
            from = "#505050";
            to = "#808080";
            angle = 45;
            relativeTo = "workspace-view";
            colorSpace = "srgb-linear";
          };
          urgentGradient = {
            from = "#800";
            to = "#a33";
            angle = 45;
          };
          width = 4;
        };
        centerFocusedColumn = "never";
        defaultColumnDisplay = "tabbed";
        defaultColumnWidth = [
          { proportion = 0.500000; }
        ];
        emptyWorkspaceAboveFirst = true;
        focusRing = {
          on = true;
          activeGradient = {
            from = "#80c8ff";
            to = "#bbddff";
            angle = 45;
            colorSpace = "oklch longer hue";
          };
          inactiveColor = "#505050";
          inactiveGradient = {
            from = "#505050";
            to = "#808080";
            angle = 45;
            relativeTo = "workspace-view";
          };
          urgentColor = "#9b0000";
          width = 4;
        };
        gaps = 16;
        insertHint = {
          on = true;
          color = "#ffc87f80";
        };
        presetColumnWidths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];
        presetWindowHeights = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];
        shadow = {
          color = "#00000070";
          drawBehindWindow = true;
          offset = {
            x = 0;
            y = 5;
          };
          softness = 30;
          spread = 5;
        };
        struts = {
          bottom = 64;
          left = 64;
          right = 64;
          top = 64;
        };
        tabIndicator = {
          on = true;
          activeColor = "red";
          activeGradient = {
            from = "#80c8ff";
            to = "#bbddff";
            angle = 45;
          };
          cornerRadius = 8;
          gap = 5;
          gapsBetweenTabs = 2;
          hideWhenSingleTab = true;
          inactiveColor = "gray";
          inactiveGradient = {
            from = "#505050";
            to = "#808080";
            angle = 45;
            relativeTo = "workspace-view";
          };
          length.totalProportion = 1.0;
          placeWithinColumn = true;
          position = "right";
          urgentColor = "blue";
          urgentGradient = {
            from = "#800";
            to = "#a33";
            angle = 45;
          };
          width = 4;
        };
      };
      animations = {
        workspaceSwitch.spring = {
          dampingRatio = 1.0;
          stiffness = 1000;
          epsilon = 0.0001;
        };

        windowOpen.ease = {
          durationMs = 150;
          curve = "ease-out-expo";
        };

        windowClose.ease = {
          durationMs = 150;
          curve = "ease-out-quad";
        };

        horizontalViewMovement.spring = {
          dampingRatio = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };

        windowMovement.spring = {
          dampingRatio = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };

        windowResize.spring = {
          dampingRatio = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };

        configNotificationOpenClose.spring = {
          dampingRatio = 0.6;
          stiffness = 1000;
          epsilon = 0.001;
        };

        exitConfirmationOpenClose.spring = {
          dampingRatio = 0.6;
          stiffness = 500;
          epsilon = 0.01;
        };

        screenshotUiOpen.ease = {
          durationMs = 200;
          curve = "cubic-bezier";
          controlPoints = [
            0.05
            0.7
            0.1
            1
          ];
        };

        overviewOpenClose.spring = {
          dampingRatio = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };

        recentWindowsClose.spring = {
          dampingRatio = 1.0;
          stiffness = 800;
          epsilon = 0.001;
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/niri/config.kdl
    assertFileContent $(normalizeStorePaths home-files/.config/niri/config.kdl) \
      ${./niri-minimal.kdl}
  '';
}
