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
        height: Absolute(0),
        margin: 0,
        hide_icons: false,
        ignore_exclusive_zones: false,
        layer: Overlay,
        hide_plugin_info: false,
        close_on_click: false,
        show_results_immediately: false,
        max_entries: Some(10),
        plugins: ["@applications@/lib/libapplications.so"],
      )
    ''}
  '';
}
