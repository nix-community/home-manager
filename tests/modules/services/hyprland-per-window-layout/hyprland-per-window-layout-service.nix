{ config, ... }:

{
  services.hyprland-per-window-layout = {
    enable = true;
    systemdTarget = "hyprland-session.target";

    settings = {
      keyboards = [ "lenovo-keyboard" ];

      default_layouts = [{ "1" = [ "org.telegram.desktop" ]; }];
    };
  };

  test.stubs = {
    hyprland = { };
    hyprland-per-window-layout = { };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/hyprland-per-window-layout.service
    optionsFile=home-files/.config/hyprland-per-window-layout/options.toml

    assertFileExists $serviceFile
    assertFileExists $optionsFile

    assertFileContent $(normalizeStorePaths $serviceFile) ${
      ./hyprland-per-window-layout-service-expected.service
    }
    assertFileContent $optionsFile ${
      ./hyprland-per-window-layout-service-expected.toml
    }
  '';
}
