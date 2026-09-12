{ config, ... }:
{
  programs.anyrun = {
    enable = true;
    config = {
      plugins = [
        (config.lib.test.mkStubPackage {
          name = "applications";
          outPath = "@applications@";
        })
      ];
      y.fraction = 2.0e-2;
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = false;
      closeOnClick = false;
      showResultsImmediately = false;
      maxEntries = 10;
      keybinds = [
        {
          key = "GDK_KEY_j";
          action = "down";
        }
        {
          ctrl = true;
          alt = false;
          shift = true;
          key = "GDK_KEY_k";
          action = "up";
        }
      ];
      extraLines = ''
        margin: 0,
      '';
    };

    extraConfigFiles = {
      "applications.ron".text = ''
        Config(
          desktop_actions: true,
          max_entries: 10,
          terminal: Some("foot"),
        )
      '';
    };

    extraCss = # CSS
      ''
        box#main {
          background: rgba(30, 30, 46, 1);
          border: 2px solid #494d64;
          border-radius: 16px;
          padding: 8px;
        }
      '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/anyrun/applications.ron
    assertFileContent home-files/.config/anyrun/applications.ron \
      ${builtins.toFile "applications.ron" ''
        Config(
          desktop_actions: true,
          max_entries: 10,
          terminal: Some("foot"),
        )
      ''}


    assertFileExists home-files/.config/anyrun/style.css
    assertFileContent home-files/.config/anyrun/style.css \
      ${builtins.toFile "style.css" ''
        box#main {
          background: rgba(30, 30, 46, 1);
          border: 2px solid #494d64;
          border-radius: 16px;
          padding: 8px;
        }
      ''}

    assertFileExists home-files/.config/anyrun/config.ron
    assertFileContent \
      home-files/.config/anyrun/config.ron \
    ${builtins.toFile "config.ron" ''
      Config(
        x: Fraction(0.500000),
        y: Fraction(0.020000),
        width: Absolute(800),
        height: Absolute(1),
        hide_icons: false,
        ignore_exclusive_zones: false,
        layer: Overlay,
        keyboard_mode: Exclusive,
        hide_plugin_info: false,
        close_on_click: false,
        show_results_immediately: false,
        max_entries: Some(10),
        plugins: ["@applications@/lib/libapplications.so"],
        provider: "@anyrun-provider@/bin/anyrun-provider",
        margin: 0,

        keybinds: [
        Keybind(
        
        
        
        key: "GDK_KEY_j",
        action: Down,
      ),

      Keybind(
        ctrl: true,
        
        shift: true,
        key: "GDK_KEY_k",
        action: Up,
      ),
      ],

      )
    ''}
  '';
}
