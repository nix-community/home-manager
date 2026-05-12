{ config, lib, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = null;
    portalPackage = null;

    plugins = [
      "/path/to/plugin1"
      (config.lib.test.mkStubPackage { name = "foo"; })
    ];

    settings = {
      config = {
        input = {
          kb_layout = "ro";
          touchpad = {
            scroll_factor = 0.3;
          };
        };

        ecosystem.enforce_permissions = true;
      };

      monitor = {
        output = "desc:Monitor";
        mode = "highres";
        position = "auto-right";
        scale = 1;
        vrr = 1;
      };

      device = {
        name = "some:device";
        enabled = true;
      };

      curve = {
        _args = [
          "smoothIn"
          {
            type = "bezier";
            points = [
              [
                0.25
                1
              ]
              [
                0.5
                1
              ]
            ];
          }
        ];
      };

      animation = [
        {
          leaf = "border";
          enabled = true;
          speed = 2;
          bezier = "smoothIn";
        }
        {
          leaf = "windows";
          enabled = true;
          speed = 3;
          bezier = "smoothIn";
          style = "popin 80%";
        }
      ];

      window_rule = {
        match.class = "kitty";
        border_size = 2;
      };

      layer_rule = {
        match.namespace = "waybar";
        blur = false;
      };

      workspace_rule = {
        workspace = "1";
        monitor = "DP-1";
      };

      permission = {
        binary = "^org\\.example\\..*";
        type = "screencopy";
        mode = "deny";
      };

      gesture = {
        fingers = 3;
        direction = "left";
        action = "workspace";
      };

      exec_cmd = [ "hyprctl setcursor Bibata 24" ];

      env = [
        {
          _args = [
            "QT_QPA_PLATFORMTHEME"
            "qt5ct"
          ];
        }
        {
          _args = [
            "XCURSOR_SIZE"
            "24"
          ];
        }
      ];

      bind = [
        {
          _args = [
            "SUPER + Q"
            (lib.generators.mkLuaInline "hl.dsp.window.close()")
            { locked = true; }
          ];
        }
        {
          _args = [
            "SUPER + RETURN"
            (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("kitty")'')
          ];
        }
        {
          _args = [
            "SUPER + SHIFT + 1"
            (lib.generators.mkLuaInline ''hl.dsp.window.move({ workspace = "1", follow = false })'')
          ];
        }
      ];

      on = {
        _args = [
          "hyprland.start"
          (lib.generators.mkLuaInline ''
            function()
              hl.exec_cmd("waybar")
            end
          '')
        ];
      };
    };

    submaps = {
      resize = {
        onDispatch = "reset";
        settings = {
          bind = [
            ", q, exec, ignored-hyprlang-bind"
            {
              _args = [
                "right"
                (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = 10, y = 0, relative = true })")
                { repeating = true; }
              ];
            }
            {
              _args = [
                "left"
                (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = -10, y = 0, relative = true })")
                { repeating = true; }
              ];
            }
            {
              _args = [
                "escape"
                (lib.generators.mkLuaInline ''hl.dsp.submap("reset")'')
              ];
            }
          ];
        };
      };
    };

    extraConfig = ''
      local mainMod = "SUPER"
      local terminal = "kitty"
      hl.define_submap("resize", function()
        hl.bind("right", hl.dsp.window.move({ direction = "right" }))
      end)
      hl.on("hyprland.start", function()
        hl.exec_cmd("waybar")
      end)
      hl.config({
        decoration = {
          rounding = 4,
        },
      })
    '';
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.lua
    assertFileExists "$config"
    assertPathNotExists home-files/.config/hypr/hyprland.conf
    assertFileNotRegex "$config" "ignored-hyprlang-bind"
    normalizedConfig=$(normalizeStorePaths "$config")
    assertFileContent "$normalizedConfig" ${./lua-config.lua}
  '';
}
