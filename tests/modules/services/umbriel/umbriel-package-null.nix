{
  wayland.windowManager.umbriel = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    checkConfig = false;
    settings = {
      keybinds = {
        "Mod+Return" = "spawn kitty";
        "Mod" = "spawn noctalia msg panel-toggle launcher";
        "Mod+Q" = "window-close";
      };
      appearance = {
        prefer_no_csd = true;
        border_width = 2;
        outer_border_width = 0;
      };
    };
  };

  nmt.script = ''
    umbrielConfig=home-files/.config/umbriel/config.toml

    assertFileExists "$umbrielConfig"
    assertFileContent "$umbrielConfig" "${./umbriel-example-settings-expected.toml}"
  '';
}
