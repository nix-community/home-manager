{
  wayland.windowManager.umbriel = {
    enable = true;
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

  # Stubs with `outPath = null` produce real derivations so the files below
  # can actually be linked into `home-path`.
  test.stubs = {
    umbriel = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin $out/share/systemd/user

        touch $out/bin/umbriel
        touch $out/bin/start-umbriel
        touch $out/share/systemd/user/umbriel.service
        touch $out/share/systemd/user/umbriel-session.target
        touch $out/share/systemd/user/umbriel-shutdown.target
      '';
    };
    xdg-desktop-portal-umbriel = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/share/xdg-desktop-portal/portals

        touch $out/share/xdg-desktop-portal/portals/umbriel.portal
        touch $out/share/xdg-desktop-portal/umbriel-portals.conf
      '';
    };
  };

  nmt.script = ''
    umbrielConfig=home-files/.config/umbriel/config.toml

    assertFileExists "$umbrielConfig"
    assertFileContent "$umbrielConfig" "${./umbriel-example-settings-expected.toml}"

    assertFileExists home-path/bin/umbriel
    assertFileExists home-path/bin/start-umbriel
    assertFileExists home-path/share/systemd/user/umbriel.service
    assertFileExists home-path/share/systemd/user/umbriel-session.target
    assertFileExists home-path/share/systemd/user/umbriel-shutdown.target
    assertFileExists home-path/share/xdg-desktop-portal/portals/umbriel.portal
    assertFileExists home-path/share/xdg-desktop-portal/umbriel-portals.conf
  '';
}
